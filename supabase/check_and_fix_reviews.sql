-- 1. 현재 테이블 구조 확인
SELECT 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'reviews'
ORDER BY ordinal_position;

-- 2. 현재 shops 테이블 구조 확인
SELECT 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'shops'
AND column_name = 'id';

-- 3. 기존 reviews 테이블 백업 (데이터가 있다면)
CREATE TABLE IF NOT EXISTS reviews_backup AS 
SELECT * FROM reviews;

-- 4. 기존 뷰 삭제
DROP VIEW IF EXISTS shop_ratings CASCADE;
DROP VIEW IF EXISTS reviews_with_user CASCADE;

-- 5. 기존 테이블 삭제 및 재생성
DROP TABLE IF EXISTS reviews CASCADE;

-- 6. reviews 테이블 재생성 (shop_id를 명확히 TEXT로)
CREATE TABLE reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  shop_id TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  
  -- 외래키 제약조건
  CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_shop FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE,
  
  -- 유니크 제약조건
  UNIQUE(user_id, shop_id)
);

-- 7. 인덱스 생성
CREATE INDEX idx_reviews_shop_id ON reviews(shop_id);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);

-- 8. RLS 활성화 및 정책 설정
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view reviews" 
ON reviews FOR SELECT 
USING (true);

CREATE POLICY "Users can create own reviews" 
ON reviews FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reviews" 
ON reviews FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own reviews" 
ON reviews FOR DELETE 
USING (auth.uid() = user_id);

-- 9. shop_ratings 뷰 재생성
CREATE VIEW shop_ratings AS
SELECT 
  shop_id::TEXT as shop_id,  -- 명시적으로 TEXT로 캐스팅
  COUNT(*)::INTEGER as review_count,
  ROUND(AVG(rating)::numeric, 1)::FLOAT as average_rating,
  SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END)::INTEGER as five_star_count,
  SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END)::INTEGER as four_star_count,
  SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END)::INTEGER as three_star_count,
  SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END)::INTEGER as two_star_count,
  SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END)::INTEGER as one_star_count
FROM reviews
GROUP BY shop_id;

-- 10. reviews_with_user 뷰 재생성
CREATE VIEW reviews_with_user AS
SELECT 
  r.id,
  r.user_id,
  r.shop_id::TEXT as shop_id,  -- 명시적으로 TEXT로 캐스팅
  r.rating,
  r.comment,
  r.created_at,
  r.updated_at,
  p.full_name as user_name,
  p.avatar_url as user_avatar
FROM reviews r
LEFT JOIN profiles p ON r.user_id = p.id;

-- 11. 권한 부여
GRANT SELECT ON shop_ratings TO authenticated;
GRANT SELECT ON shop_ratings TO anon;
GRANT SELECT ON reviews_with_user TO authenticated;
GRANT SELECT ON reviews_with_user TO anon;

-- 12. 백업 데이터 복원 (있다면)
INSERT INTO reviews (id, user_id, shop_id, rating, comment, created_at, updated_at)
SELECT id, user_id, shop_id, rating, comment, created_at, updated_at
FROM reviews_backup
ON CONFLICT DO NOTHING;

-- 13. 백업 테이블 삭제
DROP TABLE IF EXISTS reviews_backup;

-- 14. 테스트 쿼리
SELECT 'Reviews table recreated successfully' as status;

-- shops 테이블의 id 타입 확인
SELECT 
    'Shop ID type: ' || data_type as info
FROM information_schema.columns
WHERE table_name = 'shops' 
AND column_name = 'id';

-- reviews 테이블의 shop_id 타입 확인
SELECT 
    'Review shop_id type: ' || data_type as info
FROM information_schema.columns
WHERE table_name = 'reviews' 
AND column_name = 'shop_id';