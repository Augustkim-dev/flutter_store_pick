-- user_type enum 수정 스크립트
-- 기존 'shop' 값을 'shop_owner'로 변경

-- 1. 현재 user_type 값 확인
SELECT DISTINCT user_type FROM profiles;

-- 2. 기본값 제거
ALTER TABLE profiles 
ALTER COLUMN user_type DROP DEFAULT;

-- 3. 임시로 user_type을 text로 변경
ALTER TABLE profiles 
ALTER COLUMN user_type TYPE text;

-- 4. 기존 enum 타입 삭제
DROP TYPE IF EXISTS user_type CASCADE;

-- 5. 새 enum 타입 생성 (올바른 값으로)
CREATE TYPE user_type AS ENUM ('general', 'shop_owner', 'admin');

-- 6. 기존 데이터 마이그레이션 (shop -> shop_owner)
UPDATE profiles 
SET user_type = 'shop_owner' 
WHERE user_type = 'shop';

-- 7. NULL 값을 'general'로 설정
UPDATE profiles 
SET user_type = 'general' 
WHERE user_type IS NULL;

-- 8. text를 다시 enum으로 변경
ALTER TABLE profiles 
ALTER COLUMN user_type TYPE user_type 
USING user_type::user_type;

-- 9. 기본값 설정
ALTER TABLE profiles 
ALTER COLUMN user_type SET DEFAULT 'general'::user_type;

-- 10. 결과 확인
SELECT id, username, user_type FROM profiles;