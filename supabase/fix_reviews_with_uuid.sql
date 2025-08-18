-- shops 테이블의 id가 UUID 타입이므로 reviews 테이블의 shop_id도 UUID로 수정

-- 1. 현재 shops 테이블의 id 타입 확인
SELECT 
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_name = 'shops'
AND column_name = 'id';

-- 2. 기존 뷰 삭제
DROP VIEW IF EXISTS shop_ratings CASCADE;
DROP VIEW IF EXISTS reviews_with_user CASCADE;

-- 3. 기존 reviews 테이블 백업
CREATE TABLE IF NOT EXISTS reviews_backup AS 
SELECT * FROM reviews;

-- 4. 기존 테이블 삭제
DROP TABLE IF EXISTS reviews CASCADE;

-- 5. reviews 테이블 재생성 (shop_id를 UUID로)
CREATE TABLE reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,  -- UUID로 변경
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  
  -- 유니크 제약조건
  UNIQUE(user_id, shop_id)
);

-- 6. 인덱스 생성
CREATE INDEX idx_reviews_shop_id ON reviews(shop_id);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);

-- 7. RLS 활성화 및 정책 설정
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

-- 8. shop_ratings 뷰 생성
CREATE VIEW shop_ratings AS
SELECT 
  shop_id::TEXT as shop_id,  -- Flutter에서 String으로 받기 위해 TEXT로 캐스팅
  COUNT(*)::INTEGER as review_count,
  COALESCE(ROUND(AVG(rating)::numeric, 1), 0.0) as average_rating,
  COALESCE(SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END), 0)::INTEGER as five_star_count,
  COALESCE(SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END), 0)::INTEGER as four_star_count,
  COALESCE(SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END), 0)::INTEGER as three_star_count,
  COALESCE(SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END), 0)::INTEGER as two_star_count,
  COALESCE(SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END), 0)::INTEGER as one_star_count
FROM reviews
GROUP BY shop_id;

-- 9. reviews_with_user 뷰 생성
CREATE VIEW reviews_with_user AS
SELECT 
  r.id::TEXT as id,
  r.user_id::TEXT as user_id,
  r.shop_id::TEXT as shop_id,  -- Flutter에서 String으로 받기 위해 TEXT로 캐스팅
  r.rating,
  r.comment,
  r.created_at,
  r.updated_at,
  p.full_name as user_name,
  p.avatar_url as user_avatar
FROM reviews r
LEFT JOIN profiles p ON r.user_id = p.id;

-- 10. 권한 부여
GRANT SELECT ON shop_ratings TO authenticated;
GRANT SELECT ON shop_ratings TO anon;
GRANT SELECT ON reviews_with_user TO authenticated;
GRANT SELECT ON reviews_with_user TO anon;

-- 11. 백업 데이터 복원 시도
-- shop_id가 TEXT였다면 UUID로 변환 시도
DO $$
BEGIN
  -- 백업 테이블이 존재하고 데이터가 있다면 복원 시도
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'reviews_backup') THEN
    BEGIN
      -- TEXT 타입의 shop_id를 UUID로 변환하여 복원
      INSERT INTO reviews (id, user_id, shop_id, rating, comment, created_at, updated_at)
      SELECT 
        id, 
        user_id, 
        CASE 
          WHEN shop_id::TEXT ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' 
          THEN shop_id::UUID
          ELSE NULL
        END,
        rating, 
        comment, 
        created_at, 
        updated_at
      FROM reviews_backup
      WHERE shop_id IS NOT NULL
      ON CONFLICT DO NOTHING;
    EXCEPTION
      WHEN OTHERS THEN
        -- 복원 실패 시 무시
        RAISE NOTICE 'Backup restoration failed: %', SQLERRM;
    END;
  END IF;
END $$;

-- 12. 백업 테이블 삭제
DROP TABLE IF EXISTS reviews_backup;

-- 13. 테스트
SELECT 'Reviews table recreated with UUID shop_id' as status;

-- 테이블 구조 확인
SELECT 
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_name = 'reviews'
ORDER BY ordinal_position;