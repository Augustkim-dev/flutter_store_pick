-- 현재 데이터베이스 상태 확인 스크립트

-- 1. profiles 테이블의 현재 구조 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'profiles' 
AND column_name = 'user_type';

-- 2. 현재 enum 타입 값들 확인
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = (
    SELECT oid FROM pg_type WHERE typname = 'user_type'
)
ORDER BY enumsortorder;

-- 3. profiles 테이블의 실제 데이터 확인
SELECT 
    id,
    username,
    user_type,
    pg_typeof(user_type) as type_info
FROM profiles
LIMIT 10;

-- 4. 각 user_type 값의 개수
SELECT 
    user_type,
    COUNT(*) as count
FROM profiles
GROUP BY user_type;

-- 5. 제약조건 확인
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'profiles'::regclass
AND contype = 'c'; -- check constraints