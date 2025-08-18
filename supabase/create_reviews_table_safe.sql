-- Reviews 테이블 생성 (안전 버전)

-- 기존 정책 삭제 (있는 경우)
DROP POLICY IF EXISTS "Anyone can view reviews" ON reviews;
DROP POLICY IF EXISTS "Users can create own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can update own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can delete own reviews" ON reviews;

-- Reviews 테이블 생성
CREATE TABLE IF NOT EXISTS reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  shop_id TEXT NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  
  -- 한 사용자가 한 상점에 하나의 리뷰만 작성 가능
  UNIQUE(user_id, shop_id)
);

-- 인덱스 생성 (이미 존재하는 경우 무시)
CREATE INDEX IF NOT EXISTS idx_reviews_shop_id ON reviews(shop_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at DESC);

-- RLS 활성화
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- RLS 정책 설정
-- 모든 사용자가 리뷰를 볼 수 있음
CREATE POLICY "Anyone can view reviews" 
ON reviews FOR SELECT 
USING (true);

-- 인증된 사용자는 자신의 리뷰를 작성할 수 있음
CREATE POLICY "Users can create own reviews" 
ON reviews FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 사용자는 자신의 리뷰를 수정할 수 있음
CREATE POLICY "Users can update own reviews" 
ON reviews FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 사용자는 자신의 리뷰를 삭제할 수 있음
CREATE POLICY "Users can delete own reviews" 
ON reviews FOR DELETE 
USING (auth.uid() = user_id);

-- 평균 평점을 계산하는 뷰 생성
CREATE OR REPLACE VIEW shop_ratings AS
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

-- 리뷰와 사용자 정보를 조인한 뷰 생성
CREATE OR REPLACE VIEW reviews_with_user AS
SELECT 
  r.*,
  p.full_name as user_name,
  p.avatar_url as user_avatar
FROM reviews r
LEFT JOIN profiles p ON r.user_id = p.id;

-- 테스트: 테이블과 뷰가 제대로 생성되었는지 확인
SELECT 'Reviews table created successfully' as message
WHERE EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'reviews'
);

SELECT 'shop_ratings view created successfully' as message
WHERE EXISTS (
  SELECT FROM information_schema.views 
  WHERE table_name = 'shop_ratings'
);

SELECT 'reviews_with_user view created successfully' as message
WHERE EXISTS (
  SELECT FROM information_schema.views 
  WHERE table_name = 'reviews_with_user'
);