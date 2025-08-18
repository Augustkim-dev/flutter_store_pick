-- 간단한 버전: 백업 복원 없이 테이블만 생성

-- 1. 기존 뷰 삭제
DROP VIEW IF EXISTS shop_ratings CASCADE;
DROP VIEW IF EXISTS reviews_with_user CASCADE;

-- 2. 기존 테이블 삭제 (백업 생략)
DROP TABLE IF EXISTS reviews CASCADE;

-- 3. reviews 테이블 생성 (shop_id를 UUID로)
CREATE TABLE reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  
  UNIQUE(user_id, shop_id)
);

-- 4. 인덱스 생성
CREATE INDEX idx_reviews_shop_id ON reviews(shop_id);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);

-- 5. RLS 활성화 및 정책 설정
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

-- 6. shop_ratings 뷰 생성
CREATE VIEW shop_ratings AS
SELECT 
  shop_id::TEXT as shop_id,
  COUNT(*)::INTEGER as review_count,
  COALESCE(ROUND(AVG(rating)::numeric, 1), 0.0) as average_rating,
  COALESCE(SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END), 0)::INTEGER as five_star_count,
  COALESCE(SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END), 0)::INTEGER as four_star_count,
  COALESCE(SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END), 0)::INTEGER as three_star_count,
  COALESCE(SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END), 0)::INTEGER as two_star_count,
  COALESCE(SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END), 0)::INTEGER as one_star_count
FROM reviews
GROUP BY shop_id;

-- 7. reviews_with_user 뷰 생성
CREATE VIEW reviews_with_user AS
SELECT 
  r.id::TEXT as id,
  r.user_id::TEXT as user_id,
  r.shop_id::TEXT as shop_id,
  r.rating,
  r.comment,
  r.created_at,
  r.updated_at,
  p.full_name as user_name,
  p.avatar_url as user_avatar
FROM reviews r
LEFT JOIN profiles p ON r.user_id = p.id;

-- 8. 권한 부여
GRANT SELECT ON shop_ratings TO authenticated;
GRANT SELECT ON shop_ratings TO anon;
GRANT SELECT ON reviews_with_user TO authenticated;
GRANT SELECT ON reviews_with_user TO anon;

-- 9. 테스트
SELECT 'Reviews table created successfully with UUID shop_id' as status;

-- 구조 확인
SELECT 
    table_name,
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_name IN ('shops', 'reviews')
AND column_name IN ('id', 'shop_id')
ORDER BY table_name, column_name;