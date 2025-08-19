-- Phase 8: 관리자 기능 구현 (전체 스크립트)
-- 이 스크립트는 user_type enum이 이미 존재하는 경우를 가정합니다

-- 1. shops 테이블에 owner_id 컬럼 추가 (상점 소유자 연결)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'shops' AND column_name = 'owner_id'
    ) THEN
        ALTER TABLE shops ADD COLUMN owner_id UUID REFERENCES profiles(id);
    END IF;
END$$;

-- 2. business_hours 테이블 생성 (영업시간 관리)
CREATE TABLE IF NOT EXISTS business_hours (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
    day_of_week INTEGER CHECK (day_of_week BETWEEN 0 AND 6), -- 0: 일요일, 1: 월요일, ..., 6: 토요일
    open_time TIME,
    close_time TIME,
    is_closed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
    UNIQUE(shop_id, day_of_week)
);

-- 3. shop_brands 테이블 생성 (상점-브랜드 연결)
CREATE TABLE IF NOT EXISTS shop_brands (
    shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
    brand_id UUID REFERENCES brands(id) ON DELETE CASCADE,
    is_main_brand BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
    PRIMARY KEY (shop_id, brand_id)
);

-- 4. shop_stats 뷰 생성 (상점 통계 대시보드용)
CREATE OR REPLACE VIEW shop_stats AS
SELECT 
    s.id as shop_id,
    s.name as shop_name,
    s.owner_id,
    COUNT(DISTINCT r.id) as review_count,
    COALESCE(AVG(r.rating), 0) as average_rating,
    COUNT(DISTINCT f.user_id) as favorite_count
FROM shops s
LEFT JOIN reviews r ON s.id = r.shop_id
LEFT JOIN favorites f ON s.id = f.shop_id
GROUP BY s.id, s.name, s.owner_id;

-- 5. RLS 정책 업데이트

-- shops 테이블 RLS - 소유자만 수정 가능
DROP POLICY IF EXISTS "Shop owners can update own shops" ON shops;
CREATE POLICY "Shop owners can update own shops" ON shops
    FOR UPDATE USING (
        auth.uid() = owner_id OR 
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND user_type = 'admin'
        )
    );

DROP POLICY IF EXISTS "Shop owners can insert shops" ON shops;
CREATE POLICY "Shop owners can insert shops" ON shops
    FOR INSERT WITH CHECK (
        auth.uid() = owner_id OR
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND user_type IN ('shop_owner', 'admin')
        )
    );

-- business_hours 테이블 RLS
ALTER TABLE business_hours ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view business hours" ON business_hours;
CREATE POLICY "Anyone can view business hours" ON business_hours
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Shop owners can manage business hours" ON business_hours;
CREATE POLICY "Shop owners can manage business hours" ON business_hours
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM shops 
            WHERE id = business_hours.shop_id 
            AND (owner_id = auth.uid() OR EXISTS (
                SELECT 1 FROM profiles 
                WHERE id = auth.uid() AND user_type = 'admin'
            ))
        )
    );

-- shop_brands 테이블 RLS
ALTER TABLE shop_brands ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view shop brands" ON shop_brands;
CREATE POLICY "Anyone can view shop brands" ON shop_brands
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Shop owners can manage shop brands" ON shop_brands;
CREATE POLICY "Shop owners can manage shop brands" ON shop_brands
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM shops 
            WHERE id = shop_brands.shop_id 
            AND (owner_id = auth.uid() OR EXISTS (
                SELECT 1 FROM profiles 
                WHERE id = auth.uid() AND user_type = 'admin'
            ))
        )
    );

-- 6. 함수: 상점 통계 가져오기
CREATE OR REPLACE FUNCTION get_shop_stats(shop_uuid UUID)
RETURNS TABLE (
    review_count BIGINT,
    average_rating NUMERIC,
    favorite_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT r.id) as review_count,
        COALESCE(AVG(r.rating), 0) as average_rating,
        COUNT(DISTINCT f.user_id) as favorite_count
    FROM shops s
    LEFT JOIN reviews r ON s.id = r.shop_id
    LEFT JOIN favorites f ON s.id = f.shop_id
    WHERE s.id = shop_uuid
    GROUP BY s.id;
END;
$$ LANGUAGE plpgsql;

-- 7. 테스트 데이터: 첫 번째 사용자를 상점 소유자로 설정
DO $$
DECLARE
    first_user_id UUID;
    first_shop_id UUID;
BEGIN
    -- 'August' 사용자 찾기 (또는 첫 번째 사용자)
    SELECT id INTO first_user_id 
    FROM profiles 
    WHERE username = 'August' OR id IS NOT NULL
    LIMIT 1;
    
    IF first_user_id IS NOT NULL THEN
        -- 사용자를 shop_owner로 변경 (이미 shop_owner가 아닌 경우만)
        UPDATE profiles 
        SET user_type = 'shop_owner' 
        WHERE id = first_user_id 
        AND user_type != 'shop_owner';
        
        -- 첫 번째 오프라인 상점 찾기
        SELECT id INTO first_shop_id 
        FROM shops 
        WHERE shop_type IN ('offline', 'hybrid') 
        AND owner_id IS NULL
        LIMIT 1;
        
        IF first_shop_id IS NOT NULL THEN
            -- 상점에 owner_id 설정
            UPDATE shops 
            SET owner_id = first_user_id 
            WHERE id = first_shop_id;
            
            RAISE NOTICE 'User % set as owner of shop %', first_user_id, first_shop_id;
        END IF;
    END IF;
END$$;

-- 8. 영업시간 샘플 데이터 (소유자가 있는 상점만)
INSERT INTO business_hours (shop_id, day_of_week, open_time, close_time, is_closed)
SELECT 
    s.id,
    day_num,
    CASE 
        WHEN day_num = 0 THEN '10:00'::TIME  -- 일요일
        WHEN day_num = 6 THEN '10:00'::TIME  -- 토요일
        ELSE '09:00'::TIME  -- 평일
    END as open_time,
    CASE 
        WHEN day_num = 0 THEN '18:00'::TIME  -- 일요일
        WHEN day_num = 6 THEN '19:00'::TIME  -- 토요일
        ELSE '20:00'::TIME  -- 평일
    END as close_time,
    false as is_closed
FROM shops s
CROSS JOIN generate_series(0, 6) as day_num
WHERE s.owner_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM business_hours bh 
    WHERE bh.shop_id = s.id AND bh.day_of_week = day_num
)
ON CONFLICT DO NOTHING;

-- 9. 결과 확인
SELECT 
    p.id, 
    p.username, 
    p.user_type,
    s.name as owned_shop
FROM profiles p
LEFT JOIN shops s ON s.owner_id = p.id
WHERE p.user_type = 'shop_owner';

SELECT COUNT(*) as business_hours_count FROM business_hours;