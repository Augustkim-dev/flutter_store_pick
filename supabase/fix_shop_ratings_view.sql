-- shop_ratings 뷰에 대한 접근 권한 수정

-- 기존 뷰 삭제 후 재생성 (RLS 비활성화)
DROP VIEW IF EXISTS shop_ratings CASCADE;
DROP VIEW IF EXISTS reviews_with_user CASCADE;

-- shop_ratings 뷰 재생성
CREATE VIEW shop_ratings AS
SELECT 
  shop_id,
  COUNT(*) as review_count,
  ROUND(AVG(rating)::numeric, 1) as average_rating,
  SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) as five_star_count,
  SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END) as four_star_count,
  SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END) as three_star_count,
  SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END) as two_star_count,
  SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) as one_star_count
FROM reviews
GROUP BY shop_id;

-- reviews_with_user 뷰 재생성
CREATE VIEW reviews_with_user AS
SELECT 
  r.*,
  p.full_name as user_name,
  p.avatar_url as user_avatar
FROM reviews r
LEFT JOIN profiles p ON r.user_id = p.id;

-- 뷰에 대한 권한 부여 (모든 인증된 사용자가 읽기 가능)
GRANT SELECT ON shop_ratings TO authenticated;
GRANT SELECT ON shop_ratings TO anon;
GRANT SELECT ON reviews_with_user TO authenticated;
GRANT SELECT ON reviews_with_user TO anon;

-- 테스트 쿼리: 현재 리뷰와 평점 확인
SELECT 
  s.id,
  s.name,
  sr.review_count,
  sr.average_rating
FROM shops s
LEFT JOIN shop_ratings sr ON s.id = sr.shop_id
ORDER BY s.name;

-- 리뷰 데이터 확인
SELECT 
  shop_id,
  COUNT(*) as count,
  AVG(rating) as avg_rating
FROM reviews
GROUP BY shop_id;