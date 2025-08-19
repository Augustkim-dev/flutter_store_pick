-- Step by Step: user_type enum 수정
-- 각 단계를 하나씩 실행하세요

-- Step 1: 현재 상태 확인
SELECT DISTINCT user_type FROM profiles;

-- Step 2: 기본값과 제약조건 제거
ALTER TABLE profiles 
ALTER COLUMN user_type DROP DEFAULT;

-- Step 3: user_type을 text로 변경 (USING 절 사용)
ALTER TABLE profiles 
ALTER COLUMN user_type TYPE text
USING user_type::text;

-- Step 4: 기존 enum 타입 삭제
DROP TYPE IF EXISTS user_type;

-- Step 5: 새 enum 타입 생성
CREATE TYPE user_type AS ENUM ('general', 'shop_owner', 'admin');

-- Step 6: 기존 데이터 정리 (shop -> shop_owner)
UPDATE profiles 
SET user_type = 'shop_owner' 
WHERE user_type = 'shop';

-- Step 7: NULL 값 처리
UPDATE profiles 
SET user_type = 'general' 
WHERE user_type IS NULL OR user_type = '';

-- Step 8: 잘못된 값 확인 및 수정
UPDATE profiles
SET user_type = 'general'
WHERE user_type NOT IN ('general', 'shop_owner', 'admin');

-- Step 9: text를 enum으로 다시 변경
ALTER TABLE profiles 
ALTER COLUMN user_type TYPE user_type 
USING user_type::user_type;

-- Step 10: 기본값 설정
ALTER TABLE profiles 
ALTER COLUMN user_type SET DEFAULT 'general'::user_type;

-- Step 11: NOT NULL 제약 추가 (옵션)
ALTER TABLE profiles 
ALTER COLUMN user_type SET NOT NULL;

-- Step 12: 결과 확인
SELECT id, username, user_type FROM profiles ORDER BY user_type;