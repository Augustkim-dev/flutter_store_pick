-- Phase 8: 사용자 권한 시스템 구현
-- profiles 테이블에 user_type 필드 추가 및 관련 기능

-- 1. user_type enum 생성 또는 수정
DO $$ 
BEGIN
    -- 기존 enum 타입이 있는지 확인
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_type') THEN
        -- 기존 enum에 'shop_owner'가 없으면 추가
        IF NOT EXISTS (
            SELECT 1 FROM pg_enum 
            WHERE enumtypid = 'user_type'::regtype AND enumlabel = 'shop_owner'
        ) THEN
            -- 기존 enum 타입 삭제하고 재생성 (더 안전한 방법)
            ALTER TABLE profiles DROP COLUMN IF EXISTS user_type;
            DROP TYPE IF EXISTS user_type;
            CREATE TYPE user_type AS ENUM ('general', 'shop_owner', 'admin');
        END IF;
    ELSE
        CREATE TYPE user_type AS ENUM ('general', 'shop_owner', 'admin');
    END IF;
END$$;

-- 2. profiles 테이블에 user_type 컬럼 추가 (이미 존재하지 않는 경우)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'user_type'
    ) THEN
        ALTER TABLE profiles ADD COLUMN user_type user_type DEFAULT 'general';
    END IF;
END$$;

-- 3. shops 테이블에 owner_id 컬럼 추가 (상점 소유자 연결)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'shops' AND column_name = 'owner_id'
    ) THEN
        ALTER TABLE shops ADD COLUMN owner_id UUID REFERENCES profiles(id);
    END IF;
END$$;

-- 4. business_hours 테이블 생성 (영업시간 관리)
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

-- 5. shop_brands 테이블 생성 (상점-브랜드 연결)
CREATE TABLE IF NOT EXISTS shop_brands (
    shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
    brand_id UUID REFERENCES brands(id) ON DELETE CASCADE,
    is_main_brand BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
    PRIMARY KEY (shop_id, brand_id)
);

-- 6. shop_stats 뷰 생성 (상점 통계 대시보드용)
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

-- 7. RLS 정책 업데이트

-- profiles 테이블 RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
CREATE POLICY "Users can view all profiles" ON profiles
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

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

-- 8. 함수: 사용자를 상점 소유자로 승급
CREATE OR REPLACE FUNCTION promote_to_shop_owner(user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE profiles 
    SET user_type = 'shop_owner' 
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. 함수: 상점 통계 가져오기
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

-- 10. 테스트 데이터: 상점 소유자 설정 (기존 상점에 owner_id 추가)
-- 첫 번째 사용자를 상점 소유자로 설정 (테스트용)
DO $$
DECLARE
    first_user_id UUID;
    first_shop_id UUID;
BEGIN
    -- 첫 번째 사용자 찾기
    SELECT id INTO first_user_id FROM profiles LIMIT 1;
    
    IF first_user_id IS NOT NULL THEN
        -- 사용자를 shop_owner로 변경
        UPDATE profiles SET user_type = 'shop_owner' WHERE id = first_user_id;
        
        -- 첫 번째 상점 찾기
        SELECT id INTO first_shop_id FROM shops WHERE shop_type = 'offline' LIMIT 1;
        
        IF first_shop_id IS NOT NULL THEN
            -- 상점에 owner_id 설정
            UPDATE shops SET owner_id = first_user_id WHERE id = first_shop_id;
        END IF;
    END IF;
END$$;

-- 11. 영업시간 샘플 데이터 (오프라인 상점용)
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
WHERE s.shop_type IN ('offline', 'hybrid')
AND NOT EXISTS (
    SELECT 1 FROM business_hours bh 
    WHERE bh.shop_id = s.id AND bh.day_of_week = day_num
)
LIMIT 42; -- 6개 상점 * 7일 = 42개 레코드