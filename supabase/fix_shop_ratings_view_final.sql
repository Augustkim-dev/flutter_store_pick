-- shop_ratings 뷰 문제 해결

-- 1. 기존 뷰 완전 삭제
DROP VIEW IF EXISTS shop_ratings CASCADE;

-- 2. 뷰를 다시 생성 (권한 문제 회피를 위해 SECURITY INVOKER 사용)
CREATE VIEW shop_ratings 
WITH (security_invoker = true) AS
SELECT 
  shop_id::TEXT as shop_id,
  COUNT(*)::INTEGER as review_count,
  ROUND(AVG(rating)::numeric, 1) as average_rating,
  SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END)::INTEGER as five_star_count,
  SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END)::INTEGER as four_star_count,
  SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END)::INTEGER as three_star_count,
  SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END)::INTEGER as two_star_count,
  SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END)::INTEGER as one_star_count
FROM reviews
GROUP BY shop_id;

-- 3. 모든 롤에 권한 부여
GRANT SELECT ON shop_ratings TO authenticated;
GRANT SELECT ON shop_ratings TO anon;
GRANT SELECT ON shop_ratings TO service_role;
GRANT SELECT ON shop_ratings TO postgres;
GRANT SELECT ON shop_ratings TO PUBLIC;

-- 4. reviews 테이블에도 SELECT 권한 확인
GRANT SELECT ON reviews TO authenticated;
GRANT SELECT ON reviews TO anon;

-- 5. 테스트: 뷰가 작동하는지 확인
SELECT * FROM shop_ratings;

-- 6. 특정 shop_id로 테스트 (실제 shop_id로 교체 필요)
-- SELECT * FROM shop_ratings WHERE shop_id = 'your-shop-id-here';

-- 7. 직접 쿼리로도 테스트
SELECT 
  shop_id::TEXT,
  COUNT(*) as cnt,
  AVG(rating) as avg
FROM reviews
GROUP BY shop_id;

-- 8. 권한 확인
SELECT 
  grantee,
  privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'shop_ratings'
ORDER BY grantee;