-- 안전한 마이그레이션 스크립트
-- 새로운 컬럼을 추가하는 방식으로 진행

-- 1. 새로운 enum 타입 생성 (다른 이름으로)
CREATE TYPE user_role AS ENUM ('general', 'shop_owner', 'admin');

-- 2. 새 컬럼 추가
ALTER TABLE profiles 
ADD COLUMN user_role user_role DEFAULT 'general';

-- 3. 기존 데이터 마이그레이션
UPDATE profiles 
SET user_role = CASE 
    WHEN user_type::text = 'shop' THEN 'shop_owner'::user_role
    WHEN user_type::text = 'admin' THEN 'admin'::user_role
    ELSE 'general'::user_role
END;

-- 4. 새 컬럼을 NOT NULL로 변경
ALTER TABLE profiles 
ALTER COLUMN user_role SET NOT NULL;

-- 5. 기존 컬럼 삭제
ALTER TABLE profiles 
DROP COLUMN user_type;

-- 6. 새 컬럼 이름을 user_type으로 변경
ALTER TABLE profiles 
RENAME COLUMN user_role TO user_type;

-- 7. 기존 enum 타입 삭제
DROP TYPE IF EXISTS user_type;

-- 8. 새 enum 타입 이름 변경
ALTER TYPE user_role RENAME TO user_type;

-- 9. 결과 확인
SELECT id, username, user_type FROM profiles;

-- 10. RLS 정책 재생성 (필요한 경우)
-- 기존 정책들이 user_type을 참조하는 경우 재생성 필요