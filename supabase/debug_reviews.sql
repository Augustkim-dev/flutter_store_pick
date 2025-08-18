-- 리뷰 시스템 디버깅 SQL

-- 1. reviews 테이블에 데이터가 있는지 확인
SELECT 
  'Reviews count' as check_item,
  COUNT(*) as value
FROM reviews;

-- 2. reviews 테이블의 데이터 확인
SELECT 
  id::TEXT,
  user_id::TEXT,
  shop_id::TEXT,
  rating,
  comment,
  created_at
FROM reviews
LIMIT 5;

-- 3. shop_ratings 뷰가 작동하는지 확인
SELECT 
  'shop_ratings view exists' as check_item,
  EXISTS (
    SELECT FROM information_schema.views 
    WHERE table_name = 'shop_ratings'
  )::TEXT as value;

-- 4. shop_ratings 뷰 데이터 확인
SELECT * FROM shop_ratings LIMIT 5;

-- 5. 특정 상점의 리뷰 개수 직접 확인
SELECT 
  shop_id::TEXT,
  COUNT(*) as review_count,
  AVG(rating) as avg_rating
FROM reviews
GROUP BY shop_id
LIMIT 5;

-- 6. 권한 확인
SELECT 
  grantee,
  privilege_type,
  table_name
FROM information_schema.role_table_grants
WHERE table_name IN ('shop_ratings', 'reviews_with_user', 'reviews')
AND grantee IN ('authenticated', 'anon', 'public')
ORDER BY table_name, grantee;

-- 7. RLS 정책 확인
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'reviews';

-- 8. 테스트: 샘플 리뷰 추가 (실제 shop_id와 user_id 필요)
-- 먼저 실제 shop_id 확인
SELECT 
  id::TEXT as shop_id,
  name
FROM shops
LIMIT 3;

-- 9. 실제 user_id 확인
SELECT 
  id::TEXT as user_id,
  full_name
FROM profiles
LIMIT 3;