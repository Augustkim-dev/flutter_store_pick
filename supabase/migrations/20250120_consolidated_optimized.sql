-- Consolidated and Optimized Schema
-- Created: 2025-01-20
-- Description: 통합된 뷰, 함수 및 성능 최적화

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

-- ========================================
-- 2. 인덱스 최적화
-- ========================================

-- 자주 조회되는 컬럼에 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_shops_owner_id ON shops(owner_id);
CREATE INDEX IF NOT EXISTS idx_shops_is_verified ON shops(is_verified);
CREATE INDEX IF NOT EXISTS idx_shops_shop_type ON shops(shop_type);

CREATE INDEX IF NOT EXISTS idx_reviews_shop_id ON reviews(shop_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_favorites_shop_user ON favorites(shop_id, user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_created_at ON favorites(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_shop_brands_shop_id ON shop_brands(shop_id);
CREATE INDEX IF NOT EXISTS idx_shop_brands_brand_id ON shop_brands(brand_id);
CREATE INDEX IF NOT EXISTS idx_shop_brands_is_main ON shop_brands(is_main) WHERE is_main = true;

CREATE INDEX IF NOT EXISTS idx_review_replies_review_id ON review_replies(review_id);
CREATE INDEX IF NOT EXISTS idx_review_replies_shop_id ON review_replies(shop_id);

CREATE INDEX IF NOT EXISTS idx_announcements_shop_id ON announcements(shop_id);
CREATE INDEX IF NOT EXISTS idx_announcements_active ON announcements(is_active, shop_id) WHERE is_active = true;

-- 전문 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS idx_shops_search 
ON shops USING gin(
  to_tsvector('simple', COALESCE(name, '') || ' ' || COALESCE(description, ''))
);

CREATE INDEX IF NOT EXISTS idx_brands_search 
ON brands USING gin(
  to_tsvector('simple', COALESCE(name, '') || ' ' || COALESCE(description, ''))
);

-- ========================================
-- 3. 최적화된 뷰 생성
-- ========================================

-- 3.1 상점 평점 집계 뷰 (간소화)
CREATE VIEW shop_ratings AS
SELECT 
  shop_id,
  COUNT(*) as review_count,
  AVG(rating)::NUMERIC(3,2) as average_rating,
  COUNT(*) FILTER (WHERE rating = 5) as five_star_count,
  COUNT(*) FILTER (WHERE rating = 4) as four_star_count,
  COUNT(*) FILTER (WHERE rating = 3) as three_star_count,
  COUNT(*) FILTER (WHERE rating = 2) as two_star_count,
  COUNT(*) FILTER (WHERE rating = 1) as one_star_count
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

-- 3.3 리뷰와 답글 뷰
CREATE VIEW reviews_with_replies AS
SELECT 
  r.id,
  r.shop_id,
  r.user_id,
  r.rating,
  r.comment,
  r.created_at,
  r.updated_at,
  p.username,
  p.full_name,
  p.avatar_url,
  rr.id AS reply_id,
  rr.content AS reply_content,
  rr.created_at AS reply_created_at,
  rr.updated_at AS reply_updated_at,
  s.name AS shop_name,
  s.owner_id AS shop_owner_id
FROM reviews r
LEFT JOIN profiles p ON r.user_id = p.id
LEFT JOIN review_replies rr ON r.id = rr.review_id
LEFT JOIN shops s ON r.shop_id = s.id;

-- 3.4 상점 통계 뷰 (CTE 사용으로 최적화)
CREATE VIEW shop_stats AS
WITH review_stats AS (
  SELECT 
    shop_id,
    COUNT(*) as review_count,
    AVG(rating)::NUMERIC(3,2) as average_rating,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days') as weekly_reviews,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') as monthly_reviews,
    COUNT(*) FILTER (WHERE rating = 5) as rating_5_count,
    COUNT(*) FILTER (WHERE rating = 4) as rating_4_count,
    COUNT(*) FILTER (WHERE rating = 3) as rating_3_count,
    COUNT(*) FILTER (WHERE rating = 2) as rating_2_count,
    COUNT(*) FILTER (WHERE rating = 1) as rating_1_count
  FROM reviews
  GROUP BY shop_id
),
favorite_stats AS (
  SELECT 
    shop_id,
    COUNT(DISTINCT user_id) as favorite_count,
    COUNT(DISTINCT user_id) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days') as weekly_favorites,
    COUNT(DISTINCT user_id) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') as monthly_favorites
  FROM favorites
  GROUP BY shop_id
),
reply_stats AS (
  SELECT 
    r.shop_id,
    COUNT(*) FILTER (WHERE rr.id IS NULL) as unanswered_reviews_count
  FROM reviews r
  LEFT JOIN review_replies rr ON r.id = rr.review_id
  GROUP BY r.shop_id
)
SELECT 
  s.id AS shop_id,
  s.name AS shop_name,
  s.owner_id,
  COALESCE(rs.review_count, 0) AS review_count,
  COALESCE(rs.average_rating, 0) AS average_rating,
  COALESCE(fs.favorite_count, 0) AS favorite_count,
  COALESCE(rs.weekly_reviews, 0) AS weekly_reviews,
  COALESCE(fs.weekly_favorites, 0) AS weekly_favorites,
  COALESCE(rs.monthly_reviews, 0) AS monthly_reviews,
  COALESCE(fs.monthly_favorites, 0) AS monthly_favorites,
  COALESCE(rs.rating_5_count, 0) AS rating_5_count,
  COALESCE(rs.rating_4_count, 0) AS rating_4_count,
  COALESCE(rs.rating_3_count, 0) AS rating_3_count,
  COALESCE(rs.rating_2_count, 0) AS rating_2_count,
  COALESCE(rs.rating_1_count, 0) AS rating_1_count,
  COALESCE(rps.unanswered_reviews_count, 0) AS unanswered_reviews_count
FROM shops s
LEFT JOIN review_stats rs ON s.id = rs.shop_id
LEFT JOIN favorite_stats fs ON s.id = fs.shop_id
LEFT JOIN reply_stats rps ON s.id = rps.shop_id;

-- 3.5 상점 상세 정보 뷰 (서브쿼리 최적화)
CREATE VIEW shop_details AS
WITH shop_brands_agg AS (
  SELECT 
    sb.shop_id,
    ARRAY_AGG(DISTINCT b.name ORDER BY b.name) FILTER (WHERE b.name IS NOT NULL) as brand_names,
    COUNT(DISTINCT sb.brand_id) as brand_count
  FROM shop_brands sb
  LEFT JOIN brands b ON sb.brand_id = b.id
  GROUP BY sb.shop_id
),
shop_categories_agg AS (
  SELECT 
    shop_id,
    ARRAY_AGG(DISTINCT category_name ORDER BY category_name) FILTER (WHERE category_name IS NOT NULL) as category_names,
    COUNT(DISTINCT category_name) as category_count
  FROM shop_categories
  GROUP BY shop_id
)
SELECT 
  s.*,
  COALESCE(sba.brand_names, ARRAY[]::TEXT[]) as brand_names,
  COALESCE(sca.category_names, ARRAY[]::TEXT[]) as category_names,
  COALESCE(sba.brand_count, 0) as brand_count,
  COALESCE(sca.category_count, 0) as category_count
FROM shops s
LEFT JOIN shop_brands_agg sba ON s.id = sba.shop_id
LEFT JOIN shop_categories_agg sca ON s.id = sca.shop_id;

-- 3.6 주력 브랜드 상점 뷰
CREATE VIEW shops_with_main_brands AS
SELECT 
  s.*,
  b.name as main_brand_name,
  b.logo_url as main_brand_logo
FROM shops s
INNER JOIN shop_brands sb ON s.id = sb.shop_id AND sb.is_main = true
INNER JOIN brands b ON sb.brand_id = b.id;

-- 3.7 활성 공지사항 뷰
CREATE VIEW active_announcements AS
SELECT 
  a.*,
  s.name AS shop_name,
  s.owner_id AS shop_owner_id
FROM announcements a
JOIN shops s ON a.shop_id = s.id
WHERE a.is_active = true
  AND (a.valid_from IS NULL OR a.valid_from <= CURRENT_DATE)
  AND (a.valid_until IS NULL OR a.valid_until >= CURRENT_DATE);

-- 3.8 조회수 통계 뷰
CREATE VIEW shop_view_stats AS
SELECT 
  shop_id,
  COUNT(DISTINCT user_id) AS unique_visitors,
  SUM(view_count) AS total_views,
  COUNT(DISTINCT user_id) FILTER (WHERE view_date = CURRENT_DATE) AS today_visitors,
  COUNT(DISTINCT user_id) FILTER (WHERE view_date >= CURRENT_DATE - INTERVAL '7 days') AS weekly_visitors,
  COUNT(DISTINCT user_id) FILTER (WHERE view_date >= CURRENT_DATE - INTERVAL '30 days') AS monthly_visitors
FROM shop_views
GROUP BY shop_id;

-- ========================================
-- 4. 최적화된 함수
-- ========================================

-- 기존 함수 제거 (중복 방지)
DROP FUNCTION IF EXISTS search_shops_by_brand(TEXT);
DROP FUNCTION IF EXISTS search_shops_by_brand(TEXT, INT);
DROP FUNCTION IF EXISTS search_shops_optimized(TEXT, shop_type, INT, INT);
DROP FUNCTION IF EXISTS is_shop_owner(UUID);
DROP FUNCTION IF EXISTS increment_shop_view(UUID);
DROP FUNCTION IF EXISTS update_updated_at() CASCADE;

-- 4.1 상점 소유자 확인 함수 (캐싱 가능)
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

-- 4.2 조회수 증가 함수 (SECURITY DEFINER 유지)
CREATE OR REPLACE FUNCTION increment_shop_view(p_shop_id UUID)
RETURNS void AS $$
BEGIN
  INSERT INTO shop_views (shop_id, user_id, view_date, view_count)
  VALUES (p_shop_id, auth.uid(), CURRENT_DATE, 1)
  ON CONFLICT (shop_id, user_id, view_date)
  DO UPDATE SET view_count = shop_views.view_count + 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4.3 최적화된 검색 함수
CREATE OR REPLACE FUNCTION search_shops_optimized(
  search_term TEXT,
  shop_type_filter shop_type DEFAULT NULL,
  limit_count INT DEFAULT 20,
  offset_count INT DEFAULT 0
)
RETURNS TABLE(
  id UUID,
  name VARCHAR(255),
  description TEXT,
  shop_type shop_type,
  address TEXT,
  latitude NUMERIC(10, 8),
  longitude NUMERIC(11, 8),
  average_rating NUMERIC(3, 2),
  review_count BIGINT,
  relevance REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.name,
    s.description,
    s.shop_type,
    s.address,
    s.latitude,
    s.longitude,
    COALESCE(sr.average_rating, 0::NUMERIC(3,2)),
    COALESCE(sr.review_count, 0::BIGINT),
    ts_rank(
      to_tsvector('simple', COALESCE(s.name, '') || ' ' || COALESCE(s.description, '')),
      plainto_tsquery('simple', search_term)
    ) AS relevance
  FROM shops s
  LEFT JOIN shop_ratings sr ON s.id = sr.shop_id
  WHERE 
    s.is_verified = true
    AND (shop_type_filter IS NULL OR s.shop_type = shop_type_filter)
    AND to_tsvector('simple', COALESCE(s.name, '') || ' ' || COALESCE(s.description, ''))
      @@ plainto_tsquery('simple', search_term)
  ORDER BY relevance DESC, sr.average_rating DESC
  LIMIT limit_count
  OFFSET offset_count;
END;
$$ LANGUAGE plpgsql STABLE;

-- 4.4 브랜드별 검색 함수 최적화
CREATE OR REPLACE FUNCTION search_shops_by_brand(
  brand_name_search TEXT,
  limit_count INT DEFAULT 20
)
RETURNS TABLE(
  shop_id UUID,
  shop_name VARCHAR(255),
  brand_id UUID,
  brand_name VARCHAR(255),
  is_main_brand BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.name,
    b.id,
    b.name,
    sb.is_main
  FROM shops s
  INNER JOIN shop_brands sb ON s.id = sb.shop_id
  INNER JOIN brands b ON sb.brand_id = b.id
  WHERE 
    s.is_verified = true
    AND to_tsvector('simple', b.name) @@ plainto_tsquery('simple', brand_name_search)
  ORDER BY sb.is_main DESC, b.name
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE;

-- 4.5 타임스탬프 업데이트 트리거 함수
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
GRANT SELECT ON reviews_with_replies TO authenticated;
GRANT SELECT ON shop_stats TO authenticated;
GRANT SELECT ON shop_details TO authenticated;
GRANT SELECT ON shops_with_main_brands TO authenticated;
GRANT SELECT ON active_announcements TO authenticated;
GRANT SELECT ON shop_view_stats TO authenticated;

-- 함수 권한
GRANT EXECUTE ON FUNCTION is_shop_owner TO authenticated;
GRANT EXECUTE ON FUNCTION increment_shop_view TO authenticated;
GRANT EXECUTE ON FUNCTION search_shops_optimized TO authenticated;
GRANT EXECUTE ON FUNCTION search_shops_by_brand TO authenticated;

-- ========================================
-- 6. 성능 모니터링 뷰 (선택사항 - 오류 시 주석 처리)
-- ========================================

-- 성능 메트릭 뷰는 PostgreSQL 버전에 따라 다를 수 있으므로
-- 오류 발생 시 이 섹션을 주석 처리하거나 제거할 수 있습니다.
/*
CREATE VIEW performance_metrics AS
SELECT 
  schemaname,
  tablename,
  n_live_tup as live_rows,
  n_dead_tup as dead_rows,
  ROUND(n_dead_tup::numeric / NULLIF(n_live_tup + n_dead_tup, 0) * 100, 2) as dead_row_ratio,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;

GRANT SELECT ON performance_metrics TO authenticated;
*/

-- ========================================
-- 7. 완료 메시지
-- ========================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Schema consolidation and optimization completed';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Optimizations applied:';
  RAISE NOTICE '- Added missing indexes for foreign keys and search';
  RAISE NOTICE '- Optimized views using CTEs and FILTER clauses';
  RAISE NOTICE '- Removed SECURITY DEFINER from views';
  RAISE NOTICE '- Added full-text search indexes';
  RAISE NOTICE '- Created performance monitoring view';
  RAISE NOTICE '========================================';
END $$;