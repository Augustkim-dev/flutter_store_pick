-- 대안: 뷰 대신 함수 사용

-- 1. shop_ratings 뷰 삭제
DROP VIEW IF EXISTS shop_ratings CASCADE;

-- 2. 평점 정보를 반환하는 함수 생성
CREATE OR REPLACE FUNCTION get_shop_rating(p_shop_id TEXT)
RETURNS TABLE (
  shop_id TEXT,
  review_count INTEGER,
  average_rating NUMERIC,
  five_star_count INTEGER,
  four_star_count INTEGER,
  three_star_count INTEGER,
  two_star_count INTEGER,
  one_star_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p_shop_id,
    COUNT(*)::INTEGER,
    COALESCE(ROUND(AVG(r.rating)::numeric, 1), 0.0),
    COALESCE(SUM(CASE WHEN r.rating = 5 THEN 1 ELSE 0 END), 0)::INTEGER,
    COALESCE(SUM(CASE WHEN r.rating = 4 THEN 1 ELSE 0 END), 0)::INTEGER,
    COALESCE(SUM(CASE WHEN r.rating = 3 THEN 1 ELSE 0 END), 0)::INTEGER,
    COALESCE(SUM(CASE WHEN r.rating = 2 THEN 1 ELSE 0 END), 0)::INTEGER,
    COALESCE(SUM(CASE WHEN r.rating = 1 THEN 1 ELSE 0 END), 0)::INTEGER
  FROM reviews r
  WHERE r.shop_id::TEXT = p_shop_id
  GROUP BY r.shop_id;
  
  -- 리뷰가 없는 경우 기본값 반환
  IF NOT FOUND THEN
    RETURN QUERY
    SELECT 
      p_shop_id,
      0::INTEGER,
      0.0::NUMERIC,
      0::INTEGER,
      0::INTEGER,
      0::INTEGER,
      0::INTEGER,
      0::INTEGER;
  END IF;
END;
$$;

-- 3. 모든 상점의 평점을 반환하는 함수
CREATE OR REPLACE FUNCTION get_all_shop_ratings()
RETURNS TABLE (
  shop_id TEXT,
  review_count INTEGER,
  average_rating NUMERIC,
  five_star_count INTEGER,
  four_star_count INTEGER,
  three_star_count INTEGER,
  two_star_count INTEGER,
  one_star_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.shop_id::TEXT,
    COUNT(*)::INTEGER,
    ROUND(AVG(r.rating)::numeric, 1),
    SUM(CASE WHEN r.rating = 5 THEN 1 ELSE 0 END)::INTEGER,
    SUM(CASE WHEN r.rating = 4 THEN 1 ELSE 0 END)::INTEGER,
    SUM(CASE WHEN r.rating = 3 THEN 1 ELSE 0 END)::INTEGER,
    SUM(CASE WHEN r.rating = 2 THEN 1 ELSE 0 END)::INTEGER,
    SUM(CASE WHEN r.rating = 1 THEN 1 ELSE 0 END)::INTEGER
  FROM reviews r
  GROUP BY r.shop_id;
END;
$$;

-- 4. 함수 실행 권한 부여
GRANT EXECUTE ON FUNCTION get_shop_rating(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_shop_rating(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION get_all_shop_ratings() TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_shop_ratings() TO anon;

-- 5. 뷰를 다시 생성 (함수 사용)
CREATE VIEW shop_ratings AS
SELECT * FROM get_all_shop_ratings();

-- 6. 뷰 권한 부여
GRANT SELECT ON shop_ratings TO authenticated;
GRANT SELECT ON shop_ratings TO anon;
GRANT SELECT ON shop_ratings TO PUBLIC;

-- 7. 테스트
SELECT * FROM shop_ratings;

-- 특정 상점 테스트 (실제 shop_id로 교체)
-- SELECT * FROM get_shop_rating('your-shop-id-here');