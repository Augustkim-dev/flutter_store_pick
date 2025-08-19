-- Step 2: 함수 테스트 (함수 생성 후 실행)

-- 1. 브랜드 테이블 확인
SELECT name, name_ko, search_keywords 
FROM brands 
WHERE name_ko IS NOT NULL
LIMIT 10;

-- 2. simple_search 함수 테스트 (가장 간단한 검색)
SELECT * FROM simple_search('레페토');
SELECT * FROM simple_search('블로치');
SELECT * FROM simple_search('가리뇽');

-- 3. search_brands 함수 테스트
SELECT * FROM search_brands('레페토');
SELECT * FROM search_brands('Repetto');
SELECT * FROM search_brands('블로');

-- 4. search_shops_by_brand 함수 테스트
SELECT * FROM search_shops_by_brand('레페토');
SELECT * FROM search_shops_by_brand('Bloch');

-- 5. suggest_brands 자동완성 테스트
SELECT * FROM suggest_brands('레', 5);
SELECT * FROM suggest_brands('Rep', 5);
SELECT * FROM suggest_brands('블', 5);

-- 6. search_all 함수 테스트 (전체 검색)
SELECT shop_id, shop_name, shop_type, shop_brands, shop_rating, search_relevance 
FROM search_all('레페토')
LIMIT 10;

SELECT shop_id, shop_name, shop_type, shop_brands, shop_rating, search_relevance 
FROM search_all('발레')
LIMIT 10;