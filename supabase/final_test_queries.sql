-- 최종 테스트 쿼리 모음

-- 1. 브랜드 한글명 확인
SELECT name, name_ko, search_keywords 
FROM brands 
WHERE name_ko IS NOT NULL;

-- 2. simple_search 테스트 (가장 간단한 검색)
-- 한글로 검색
SELECT shop_name, shop_brands, shop_rating 
FROM simple_search('레페토');

SELECT shop_name, shop_brands, shop_rating 
FROM simple_search('블로치');

SELECT shop_name, shop_brands, shop_rating 
FROM simple_search('가리뇽');

-- 영어로 검색
SELECT shop_name, shop_brands, shop_rating 
FROM simple_search('Repetto');

SELECT shop_name, shop_brands, shop_rating 
FROM simple_search('Bloch');

-- 3. search_brands 테스트
SELECT brand_name, brand_name_ko 
FROM search_brands('레페토');

SELECT brand_name, brand_name_ko 
FROM search_brands('블로');

SELECT brand_name, brand_name_ko 
FROM search_brands('가리');

-- 4. search_shops_by_brand 테스트
SELECT shop_name, matched_brands, shop_rating 
FROM search_shops_by_brand('레페토');

SELECT shop_name, matched_brands, shop_rating 
FROM search_shops_by_brand('블로치');

-- 5. 자동완성 테스트
SELECT display_name 
FROM suggest_brands('레', 10);

SELECT display_name 
FROM suggest_brands('블', 10);

SELECT display_name 
FROM suggest_brands('가', 10);

-- 6. search_all 통합 검색 테스트
SELECT shop_name, shop_brands, shop_rating, search_relevance 
FROM search_all('레페토')
ORDER BY search_relevance DESC
LIMIT 5;

SELECT shop_name, shop_brands, shop_rating, search_relevance 
FROM search_all('블로치')
ORDER BY search_relevance DESC
LIMIT 5;

SELECT shop_name, shop_brands, shop_rating, search_relevance 
FROM search_all('발레')
ORDER BY search_relevance DESC
LIMIT 10;

-- 7. 검색 결과 카운트
SELECT 
    '레페토' as search_term,
    COUNT(*) as result_count 
FROM simple_search('레페토')
UNION ALL
SELECT 
    '블로치' as search_term,
    COUNT(*) as result_count 
FROM simple_search('블로치')
UNION ALL
SELECT 
    '가리뇽' as search_term,
    COUNT(*) as result_count 
FROM simple_search('가리뇽');