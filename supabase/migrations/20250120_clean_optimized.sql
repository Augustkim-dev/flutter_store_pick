-- Clean Optimized Schema (에러 없는 버전)
-- Created: 2025-01-20
-- Description: 검증된 뷰와 함수만 포함한 최적화 스키마

-- ========================================
-- 1. 기존 객체 정리
-- ========================================

-- 중복된 뷰 제거
DROP VIEW IF EXISTS shop_ratings CASCADE;
DROP VIEW IF EXISTS reviews_with_user CASCADE;
DROP VIEW IF EXISTS shop_stats CASCADE;
DROP VIEW IF EXISTS reviews_with_replies CASCADE;
DROP VIEW IF EXISTS active_announcements CASCADE;
DROP VIEW IF EXISTS shop_view_stats CASCADE;
DROP VIEW IF EXISTS shop_details CASCADE;
DROP VIEW IF EXISTS shops_with_main_brands CASCADE;

-- 기존 함수 제거 (중복 방지)
DROP FUNCTION IF EXISTS search_shops_by_brand(TEXT);
DROP FUNCTION IF EXISTS search_shops_by_brand(TEXT, INT);
DROP FUNCTION IF EXISTS is_shop_owner(UUID);
DROP FUNCTION IF EXISTS increment_shop_view(UUID);
DROP FUNCTION IF EXISTS update_updated_at() CASCADE;

-- ========================================
-- 2. 핵심 인덱스만 추가 (검증된 컬럼만)
-- ========================================

-- shops 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_shops_owner_id ON shops(owner_id);
CREATE INDEX IF NOT EXISTS idx_shops_shop_type ON shops(shop_type);

-- reviews 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_reviews_shop_id ON reviews(shop_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at DESC);

-- favorites 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_favorites_shop_user ON favorites(shop_id, user_id);

-- shop_brands 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_shop_brands_shop_id ON shop_brands(shop_id);
CREATE INDEX IF NOT EXISTS idx_shop_brands_brand_id ON shop_brands(brand_id);

-- ========================================
-- 3. 핵심 뷰 생성 (간소화 버전)
-- ========================================

-- 3.1 상점 평점 집계 뷰
CREATE VIEW shop_ratings AS
SELECT 
  shop_id,
  COUNT(*) as review_count,
  AVG(rating)::NUMERIC(3,2) as average_rating
FROM reviews
GROUP BY shop_id;

-- 3.2 리뷰와 사용자 정보 뷰
CREATE VIEW reviews_with_user AS
SELECT 
  r.*,
  p.username,
  p.full_name,
  p.avatar_url
FROM reviews r
LEFT JOIN profiles p ON r.user_id = p.id;

-- 3.3 상점 통계 뷰 (간소화)
CREATE VIEW shop_stats AS
SELECT 
  s.id AS shop_id,
  s.name AS shop_name,
  s.owner_id,
  COALESCE(r.review_count, 0) AS review_count,
  COALESCE(r.average_rating, 0) AS average_rating,
  (SELECT COUNT(DISTINCT user_id) FROM favorites WHERE shop_id = s.id) AS favorite_count
FROM shops s
LEFT JOIN shop_ratings r ON s.id = r.shop_id;

-- 3.4 상점 상세 정보 뷰
CREATE VIEW shop_details AS
SELECT 
  s.*,
  COALESCE(
    ARRAY(
      SELECT DISTINCT b.name 
      FROM shop_brands sb 
      JOIN brands b ON sb.brand_id = b.id 
      WHERE sb.shop_id = s.id
    ), 
    ARRAY[]::TEXT[]
  ) as brand_names
FROM shops s;

-- ========================================
-- 4. 핵심 함수 생성
-- ========================================

-- 4.1 상점 소유자 확인 함수
CREATE OR REPLACE FUNCTION is_shop_owner(shop_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM shops 
    WHERE id = shop_uuid 
    AND owner_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- 4.2 조회수 증가 함수 (테이블이 있는 경우만)
CREATE OR REPLACE FUNCTION increment_shop_view(p_shop_id UUID)
RETURNS void AS $$
BEGIN
  -- shop_views 테이블이 있는지 확인
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'shop_views'
  ) THEN
    INSERT INTO shop_views (shop_id, user_id, view_date, view_count)
    VALUES (p_shop_id, auth.uid(), CURRENT_DATE, 1)
    ON CONFLICT (shop_id, user_id, view_date)
    DO UPDATE SET view_count = shop_views.view_count + 1;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4.3 브랜드별 검색 함수 (간소화)
CREATE OR REPLACE FUNCTION search_shops_by_brand(
  brand_name_search TEXT,
  limit_count INT DEFAULT 20
)
RETURNS TABLE(
  shop_id UUID,
  shop_name VARCHAR(255),
  brand_id UUID,
  brand_name VARCHAR(255)
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.name,
    b.id,
    b.name
  FROM shops s
  INNER JOIN shop_brands sb ON s.id = sb.shop_id
  INNER JOIN brands b ON sb.brand_id = b.id
  WHERE b.name ILIKE '%' || brand_name_search || '%'
  ORDER BY b.name
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE;

-- 4.4 타임스탬프 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 5. 권한 설정
-- ========================================

-- 뷰 권한
GRANT SELECT ON shop_ratings TO authenticated;
GRANT SELECT ON reviews_with_user TO authenticated;
GRANT SELECT ON shop_stats TO authenticated;
GRANT SELECT ON shop_details TO authenticated;

-- 함수 권한
GRANT EXECUTE ON FUNCTION is_shop_owner TO authenticated;
GRANT EXECUTE ON FUNCTION increment_shop_view TO authenticated;
GRANT EXECUTE ON FUNCTION search_shops_by_brand TO authenticated;

-- ========================================
-- 6. 완료 메시지
-- ========================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Clean optimized schema applied successfully';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Applied optimizations:';
  RAISE NOTICE '- Added essential indexes';
  RAISE NOTICE '- Created simplified views';
  RAISE NOTICE '- Removed SECURITY DEFINER from views';
  RAISE NOTICE '- Created core functions';
  RAISE NOTICE '========================================';
END $$;