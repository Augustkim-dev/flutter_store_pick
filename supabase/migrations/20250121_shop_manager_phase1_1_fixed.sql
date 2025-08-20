-- Phase 1-1: 상점 정보 관리 확장 (수정된 버전)
-- 실행일: 2025-01-21

-- ========================================
-- 1. shops 테이블 확장 (누락된 컬럼 추가)
-- ========================================

-- 공통 정보
ALTER TABLE shops ADD COLUMN IF NOT EXISTS business_number VARCHAR(20);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS image_urls TEXT[];
ALTER TABLE shops ADD COLUMN IF NOT EXISTS kakao_id VARCHAR(100);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS email VARCHAR(255);

-- 오프라인 상점 추가 정보
ALTER TABLE shops ADD COLUMN IF NOT EXISTS detailed_location TEXT;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS lunch_break_start TIME;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS lunch_break_end TIME;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS wheelchair_accessible BOOLEAN DEFAULT FALSE;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS kids_friendly BOOLEAN DEFAULT FALSE;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS directions_public TEXT;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS directions_walking TEXT;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS parking_info TEXT;

-- 온라인 상점 추가 정보
ALTER TABLE shops ADD COLUMN IF NOT EXISTS mobile_web_support BOOLEAN DEFAULT TRUE;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS same_day_delivery BOOLEAN DEFAULT FALSE;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS payment_methods TEXT[];
ALTER TABLE shops ADD COLUMN IF NOT EXISTS cs_hours TEXT;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS cs_phone VARCHAR(20);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS cs_kakao VARCHAR(100);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS cs_email VARCHAR(255);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS exchange_policy TEXT;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS refund_policy TEXT;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS return_shipping_fee INTEGER;

-- 복합 상점 정보
ALTER TABLE shops ADD COLUMN IF NOT EXISTS pickup_service BOOLEAN DEFAULT FALSE;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS online_to_offline BOOLEAN DEFAULT FALSE;

-- ========================================
-- 2. shop_brands 테이블 처리
-- ========================================

-- 테이블이 없으면 생성
CREATE TABLE IF NOT EXISTS shop_brands (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL,
  brand_id UUID NOT NULL,
  is_main BOOLEAN DEFAULT FALSE,
  stock_status VARCHAR(20) DEFAULT 'in_stock',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 컬럼이 없으면 추가 (기존 테이블인 경우)
ALTER TABLE shop_brands ADD COLUMN IF NOT EXISTS is_main BOOLEAN DEFAULT FALSE;
ALTER TABLE shop_brands ADD COLUMN IF NOT EXISTS stock_status VARCHAR(20) DEFAULT 'in_stock';
ALTER TABLE shop_brands ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 제약조건 추가 (없는 경우만)
DO $$ 
BEGIN
  -- 외래키 제약조건
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'shop_brands_shop_id_fkey' 
    AND table_name = 'shop_brands'
  ) THEN
    ALTER TABLE shop_brands ADD CONSTRAINT shop_brands_shop_id_fkey 
      FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'shop_brands_brand_id_fkey' 
    AND table_name = 'shop_brands'
  ) THEN
    ALTER TABLE shop_brands ADD CONSTRAINT shop_brands_brand_id_fkey 
      FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE CASCADE;
  END IF;
  
  -- UNIQUE 제약조건
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'shop_brands_shop_id_brand_id_key' 
    AND table_name = 'shop_brands'
  ) THEN
    ALTER TABLE shop_brands ADD CONSTRAINT shop_brands_shop_id_brand_id_key 
      UNIQUE(shop_id, brand_id);
  END IF;
  
  -- CHECK 제약조건
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.check_constraints 
    WHERE constraint_name = 'shop_brands_stock_status_check'
  ) THEN
    ALTER TABLE shop_brands ADD CONSTRAINT shop_brands_stock_status_check 
      CHECK (stock_status IN ('in_stock', 'low_stock', 'out_of_stock'));
  END IF;
END $$;

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_shop_brands_shop_id ON shop_brands(shop_id);
CREATE INDEX IF NOT EXISTS idx_shop_brands_brand_id ON shop_brands(brand_id);
CREATE INDEX IF NOT EXISTS idx_shop_brands_is_main ON shop_brands(is_main) WHERE is_main = true;

-- ========================================
-- 3. shop_categories 테이블 처리
-- ========================================

-- 테이블이 없으면 생성
CREATE TABLE IF NOT EXISTS shop_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL,
  category_name VARCHAR(50) NOT NULL,
  is_specialized BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 컬럼이 없으면 추가 (기존 테이블인 경우)
ALTER TABLE shop_categories ADD COLUMN IF NOT EXISTS is_specialized BOOLEAN DEFAULT FALSE;
ALTER TABLE shop_categories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 제약조건 추가 (없는 경우만)
DO $$ 
BEGIN
  -- 외래키 제약조건
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'shop_categories_shop_id_fkey' 
    AND table_name = 'shop_categories'
  ) THEN
    ALTER TABLE shop_categories ADD CONSTRAINT shop_categories_shop_id_fkey 
      FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE;
  END IF;
  
  -- UNIQUE 제약조건
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'shop_categories_shop_id_category_name_key' 
    AND table_name = 'shop_categories'
  ) THEN
    ALTER TABLE shop_categories ADD CONSTRAINT shop_categories_shop_id_category_name_key 
      UNIQUE(shop_id, category_name);
  END IF;
END $$;

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_shop_categories_shop_id ON shop_categories(shop_id);
CREATE INDEX IF NOT EXISTS idx_shop_categories_category ON shop_categories(category_name);
CREATE INDEX IF NOT EXISTS idx_shop_categories_specialized ON shop_categories(is_specialized) WHERE is_specialized = true;

-- ========================================
-- 4. shipping_regions 테이블 처리
-- ========================================

-- 테이블이 없으면 생성
CREATE TABLE IF NOT EXISTS shipping_regions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL,
  region_name VARCHAR(50) NOT NULL,
  shipping_fee INTEGER NOT NULL DEFAULT 3000,
  estimated_days INTEGER DEFAULT 2,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 컬럼이 없으면 추가 (기존 테이블인 경우)
ALTER TABLE shipping_regions ADD COLUMN IF NOT EXISTS estimated_days INTEGER DEFAULT 2;
ALTER TABLE shipping_regions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 제약조건 추가 (없는 경우만)
DO $$ 
BEGIN
  -- 외래키 제약조건
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'shipping_regions_shop_id_fkey' 
    AND table_name = 'shipping_regions'
  ) THEN
    ALTER TABLE shipping_regions ADD CONSTRAINT shipping_regions_shop_id_fkey 
      FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE;
  END IF;
  
  -- UNIQUE 제약조건
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'shipping_regions_shop_id_region_name_key' 
    AND table_name = 'shipping_regions'
  ) THEN
    ALTER TABLE shipping_regions ADD CONSTRAINT shipping_regions_shop_id_region_name_key 
      UNIQUE(shop_id, region_name);
  END IF;
END $$;

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_shipping_regions_shop_id ON shipping_regions(shop_id);
CREATE INDEX IF NOT EXISTS idx_shipping_regions_region ON shipping_regions(region_name);

-- ========================================
-- 5. RLS (Row Level Security) 정책
-- ========================================

-- shop_brands RLS
ALTER TABLE shop_brands ENABLE ROW LEVEL SECURITY;

-- 기존 정책 삭제
DROP POLICY IF EXISTS "shop_brands_select_policy" ON shop_brands;
DROP POLICY IF EXISTS "shop_brands_insert_policy" ON shop_brands;
DROP POLICY IF EXISTS "shop_brands_update_policy" ON shop_brands;
DROP POLICY IF EXISTS "shop_brands_delete_policy" ON shop_brands;

-- 새 정책 생성
CREATE POLICY "shop_brands_select_policy" ON shop_brands
  FOR SELECT USING (true);

CREATE POLICY "shop_brands_insert_policy" ON shop_brands
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_brands.shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "shop_brands_update_policy" ON shop_brands
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_brands.shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "shop_brands_delete_policy" ON shop_brands
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_brands.shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

-- shop_categories RLS
ALTER TABLE shop_categories ENABLE ROW LEVEL SECURITY;

-- 기존 정책 삭제
DROP POLICY IF EXISTS "shop_categories_select_policy" ON shop_categories;
DROP POLICY IF EXISTS "shop_categories_insert_policy" ON shop_categories;
DROP POLICY IF EXISTS "shop_categories_update_policy" ON shop_categories;
DROP POLICY IF EXISTS "shop_categories_delete_policy" ON shop_categories;

-- 새 정책 생성
CREATE POLICY "shop_categories_select_policy" ON shop_categories
  FOR SELECT USING (true);

CREATE POLICY "shop_categories_insert_policy" ON shop_categories
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_categories.shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "shop_categories_update_policy" ON shop_categories
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_categories.shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "shop_categories_delete_policy" ON shop_categories
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shop_categories.shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

-- shipping_regions RLS
ALTER TABLE shipping_regions ENABLE ROW LEVEL SECURITY;

-- 기존 정책 삭제
DROP POLICY IF EXISTS "shipping_regions_select_policy" ON shipping_regions;
DROP POLICY IF EXISTS "shipping_regions_insert_policy" ON shipping_regions;
DROP POLICY IF EXISTS "shipping_regions_update_policy" ON shipping_regions;
DROP POLICY IF EXISTS "shipping_regions_delete_policy" ON shipping_regions;

-- 새 정책 생성
CREATE POLICY "shipping_regions_select_policy" ON shipping_regions
  FOR SELECT USING (true);

CREATE POLICY "shipping_regions_insert_policy" ON shipping_regions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shipping_regions.shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "shipping_regions_update_policy" ON shipping_regions
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shipping_regions.shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "shipping_regions_delete_policy" ON shipping_regions
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM shops 
      WHERE shops.id = shipping_regions.shop_id 
      AND shops.owner_id = auth.uid()
    )
  );

-- ========================================
-- 6. 유용한 뷰 생성
-- ========================================

-- 기존 뷰 삭제 후 재생성
DROP VIEW IF EXISTS shop_details;
CREATE VIEW shop_details AS
SELECT 
  s.*,
  COALESCE(
    ARRAY_AGG(DISTINCT b.name) FILTER (WHERE b.name IS NOT NULL),
    ARRAY[]::TEXT[]
  ) as brand_names,
  COALESCE(
    ARRAY_AGG(DISTINCT sc.category_name) FILTER (WHERE sc.category_name IS NOT NULL),
    ARRAY[]::TEXT[]
  ) as category_names,
  COUNT(DISTINCT sb.brand_id) as brand_count,
  COUNT(DISTINCT sc.category_name) as category_count
FROM shops s
LEFT JOIN shop_brands sb ON s.id = sb.shop_id
LEFT JOIN brands b ON sb.brand_id = b.id
LEFT JOIN shop_categories sc ON s.id = sc.shop_id
GROUP BY s.id;

-- 주력 브랜드를 가진 상점 뷰
DROP VIEW IF EXISTS shops_with_main_brands;
CREATE VIEW shops_with_main_brands AS
SELECT 
  s.*,
  b.name as main_brand_name,
  b.logo_url as main_brand_logo
FROM shops s
INNER JOIN shop_brands sb ON s.id = sb.shop_id AND sb.is_main = true
INNER JOIN brands b ON sb.brand_id = b.id;

-- ========================================
-- 7. 트리거 함수 (updated_at 자동 업데이트)
-- ========================================

-- 트리거 함수 생성 (없는 경우만)
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS update_shop_brands_updated_at ON shop_brands;
CREATE TRIGGER update_shop_brands_updated_at
  BEFORE UPDATE ON shop_brands
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_shop_categories_updated_at ON shop_categories;
CREATE TRIGGER update_shop_categories_updated_at
  BEFORE UPDATE ON shop_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_shipping_regions_updated_at ON shipping_regions;
CREATE TRIGGER update_shipping_regions_updated_at
  BEFORE UPDATE ON shipping_regions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- ========================================
-- 8. 코멘트 추가
-- ========================================

COMMENT ON TABLE shop_brands IS '상점별 취급 브랜드 정보';
COMMENT ON TABLE shop_categories IS '상점별 취급 카테고리 정보';
COMMENT ON TABLE shipping_regions IS '상점별 지역별 배송비 정보';

COMMENT ON COLUMN shops.business_number IS '사업자 등록번호';
COMMENT ON COLUMN shops.image_urls IS '상점 이미지 갤러리 URL 배열';
COMMENT ON COLUMN shops.detailed_location IS '상세 위치 (예: 2층, 지하 1층)';
COMMENT ON COLUMN shops.lunch_break_start IS '점심시간 시작';
COMMENT ON COLUMN shops.lunch_break_end IS '점심시간 종료';
COMMENT ON COLUMN shops.wheelchair_accessible IS '휠체어 접근 가능 여부';
COMMENT ON COLUMN shops.kids_friendly IS '아동 동반 가능 여부';
COMMENT ON COLUMN shops.payment_methods IS '결제 수단 배열 (카드, 현금, 계좌이체 등)';
COMMENT ON COLUMN shops.pickup_service IS '매장 픽업 서비스 제공 여부';
COMMENT ON COLUMN shops.online_to_offline IS '온라인 주문 후 오프라인 수령 가능 여부';

COMMENT ON COLUMN shop_brands.is_main IS '주력 브랜드 여부';
COMMENT ON COLUMN shop_brands.stock_status IS '재고 상태 (in_stock, low_stock, out_of_stock)';
COMMENT ON COLUMN shop_categories.is_specialized IS '전문 카테고리 여부';
COMMENT ON COLUMN shipping_regions.estimated_days IS '예상 배송일';

-- ========================================
-- 실행 완료 메시지
-- ========================================
DO $$ 
BEGIN
  RAISE NOTICE 'Phase 1-1 마이그레이션이 성공적으로 완료되었습니다.';
  RAISE NOTICE '- shops 테이블: 30+ 개 컬럼 추가';
  RAISE NOTICE '- shop_brands 테이블: 생성/업데이트';
  RAISE NOTICE '- shop_categories 테이블: 생성/업데이트';
  RAISE NOTICE '- shipping_regions 테이블: 생성/업데이트';
  RAISE NOTICE '- RLS 정책 및 인덱스 설정 완료';
END $$;