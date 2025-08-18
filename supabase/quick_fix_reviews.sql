-- 간단한 해결 방법: 뷰를 다시 생성하여 타입 캐스팅 명확히 하기

-- 1. 기존 뷰 삭제
DROP VIEW IF EXISTS shop_ratings CASCADE;
DROP VIEW IF EXISTS reviews_with_user CASCADE;

-- 2. shop_ratings 뷰 재생성 (shop_id를 TEXT로 명확히)
CREATE OR REPLACE VIEW shop_ratings AS
SELECT 
  CAST(shop_id AS TEXT) as shop_id,
  COUNT(*)::INT as review_count,
  COALESCE(ROUND(AVG(rating)::numeric, 1), 0.0) as average_rating,
  COALESCE(SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END), 0) as five_star_count,
  COALESCE(SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END), 0) as four_star_count,
  COALESCE(SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END), 0) as three_star_count,
  COALESCE(SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END), 0) as two_star_count,
  COALESCE(SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END), 0) as one_star_count
FROM reviews
GROUP BY shop_id;

-- 3. reviews_with_user 뷰 재생성
CREATE OR REPLACE VIEW reviews_with_user AS
SELECT 
  r.id::TEXT as id,
  r.user_id::TEXT as user_id,
  CAST(r.shop_id AS TEXT) as shop_id,
  r.rating,
  r.comment,
  r.created_at,
  r.updated_at,
  p.full_name as user_name,
  p.avatar_url as user_avatar
FROM reviews r
LEFT JOIN profiles p ON r.user_id = p.id;

-- 4. 권한 부여
GRANT SELECT ON shop_ratings TO authenticated;
GRANT SELECT ON shop_ratings TO anon;
GRANT SELECT ON reviews_with_user TO authenticated;
GRANT SELECT ON reviews_with_user TO anon;

-- 5. 테스트: 뷰가 정상 작동하는지 확인
SELECT * FROM shop_ratings LIMIT 5;
SELECT * FROM reviews_with_user LIMIT 5;