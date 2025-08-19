-- Step 0: 테이블 구조 확인 (문제 진단용)

-- 1. brands 테이블 구조 확인
SELECT 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'brands'
ORDER BY ordinal_position;

-- 2. shops 테이블 구조 확인
SELECT 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'shops'
ORDER BY ordinal_position;

-- 3. brands 테이블에 name_ko와 search_keywords 컬럼이 있는지 확인
SELECT 
    EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'brands' AND column_name = 'name_ko'
    ) as has_name_ko,
    EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'brands' AND column_name = 'search_keywords'
    ) as has_search_keywords;

-- 4. brands 데이터 샘플 확인
SELECT id, name, name_ko, search_keywords
FROM brands
LIMIT 5;

-- 5. shops 데이터 샘플 확인
SELECT id, name, shop_type, brands, rating
FROM shops
LIMIT 5;

-- 6. 특정 브랜드 검색 (수동)
SELECT * FROM brands 
WHERE LOWER(name) LIKE '%repetto%' 
   OR LOWER(COALESCE(name_ko, '')) LIKE '%레페토%';

-- 7. 브랜드를 가진 상점 확인
SELECT s.name, s.brands 
FROM shops s 
WHERE 'Repetto' = ANY(s.brands)
   OR 'REPETTO' = ANY(s.brands)
   OR 'repetto' = ANY(s.brands);

-- 8. 함수 목록 확인
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('search_brands', 'simple_search', 'search_all', 'suggest_brands')
ORDER BY routine_name;