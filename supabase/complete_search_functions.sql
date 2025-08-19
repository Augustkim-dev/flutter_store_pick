-- 완전한 검색 함수 구현 (모든 필요한 함수 포함)

-- 1. 기존 함수들 삭제 (있을 경우)
DROP FUNCTION IF EXISTS search_brands(text);
DROP FUNCTION IF EXISTS search_shops_by_brand(text);
DROP FUNCTION IF EXISTS search_all(text);
DROP FUNCTION IF EXISTS suggest_brands(text, integer);

-- 2. search_brands 함수 생성 (기본 브랜드 검색)
CREATE OR REPLACE FUNCTION search_brands(search_query TEXT)
RETURNS TABLE(
  id UUID,
  name TEXT,
  name_ko TEXT,
  logo_url TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT b.id, b.name, b.name_ko, b.logo_url
  FROM brands b
  WHERE 
    -- 영어명 검색 (대소문자 구분 없음)
    LOWER(b.name) LIKE LOWER('%' || search_query || '%')
    -- 한글명 검색
    OR LOWER(COALESCE(b.name_ko, '')) LIKE LOWER('%' || search_query || '%')
    -- 검색 키워드 배열 검색 (NULL 체크 추가)
    OR (
      b.search_keywords IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM unnest(b.search_keywords) AS keyword
        WHERE LOWER(keyword) LIKE LOWER('%' || search_query || '%')
      )
    );
END;
$$ LANGUAGE plpgsql;

-- 3. search_shops_by_brand 함수 생성
CREATE OR REPLACE FUNCTION search_shops_by_brand(search_query TEXT)
RETURNS TABLE(
  shop_id UUID,
  shop_name TEXT,
  shop_type TEXT,
  shop_description TEXT,
  shop_rating FLOAT,
  matched_brands TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  WITH matched_brands AS (
    SELECT * FROM search_brands(search_query)
  )
  SELECT DISTINCT
    s.id as shop_id,
    s.name as shop_name,
    s.shop_type::TEXT as shop_type,
    s.description as shop_description,
    s.rating as shop_rating,
    array_agg(DISTINCT mb.name) as matched_brands
  FROM shops s
  CROSS JOIN matched_brands mb
  WHERE mb.name = ANY(s.brands)
  GROUP BY s.id, s.name, s.shop_type, s.description, s.rating;
END;
$$ LANGUAGE plpgsql;

-- 4. search_all 통합 검색 함수
CREATE OR REPLACE FUNCTION search_all(query_text TEXT)
RETURNS TABLE(
  id UUID,
  name TEXT,
  shop_type TEXT,
  description TEXT,
  brands TEXT[],
  rating FLOAT,
  review_count INTEGER,
  image_url TEXT,
  address TEXT,
  phone TEXT,
  latitude FLOAT,
  longitude FLOAT,
  website_url TEXT,
  search_relevance FLOAT
) AS $$
BEGIN
  RETURN QUERY
  WITH brand_matches AS (
    -- 브랜드 검색 (한글/영어 통합)
    SELECT shop_id, COUNT(*) as brand_match_count
    FROM search_shops_by_brand(query_text)
    GROUP BY shop_id
  ),
  name_matches AS (
    -- 상점명/설명 검색
    SELECT 
      s.id,
      CASE 
        WHEN LOWER(s.name) LIKE LOWER('%' || query_text || '%') THEN 3
        WHEN LOWER(s.description) LIKE LOWER('%' || query_text || '%') THEN 1
        ELSE 0
      END as name_match_score
    FROM shops s
  )
  SELECT 
    s.id,
    s.name,
    s.shop_type::TEXT,
    s.description,
    s.brands,
    s.rating,
    s.review_count,
    s.image_url,
    s.address,
    s.phone,
    s.latitude,
    s.longitude,
    s.website_url,
    -- 검색 관련도 점수 (브랜드 매치는 더 높은 가중치)
    (COALESCE(bm.brand_match_count, 0) * 5 + COALESCE(nm.name_match_score, 0))::FLOAT as search_relevance
  FROM shops s
  LEFT JOIN brand_matches bm ON bm.shop_id = s.id
  LEFT JOIN name_matches nm ON nm.id = s.id
  WHERE 
    bm.shop_id IS NOT NULL 
    OR nm.name_match_score > 0
  ORDER BY search_relevance DESC, s.rating DESC;
END;
$$ LANGUAGE plpgsql;

-- 5. suggest_brands 자동완성 함수
CREATE OR REPLACE FUNCTION suggest_brands(search_query TEXT, limit_count INTEGER DEFAULT 10)
RETURNS TABLE(
  id UUID,
  name TEXT,
  name_ko TEXT,
  display_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.id,
    b.name,
    b.name_ko,
    CASE 
      WHEN b.name_ko IS NOT NULL THEN b.name || ' (' || b.name_ko || ')'
      ELSE b.name
    END as display_name
  FROM brands b
  WHERE 
    LOWER(b.name) LIKE LOWER(search_query || '%')
    OR LOWER(COALESCE(b.name_ko, '')) LIKE LOWER(search_query || '%')
    OR (
      b.search_keywords IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM unnest(b.search_keywords) AS keyword
        WHERE LOWER(keyword) LIKE LOWER(search_query || '%')
      )
    )
  ORDER BY 
    CASE 
      WHEN LOWER(b.name) = LOWER(search_query) THEN 1
      WHEN LOWER(COALESCE(b.name_ko, '')) = LOWER(search_query) THEN 2
      WHEN LOWER(b.name) LIKE LOWER(search_query || '%') THEN 3
      WHEN LOWER(COALESCE(b.name_ko, '')) LIKE LOWER(search_query || '%') THEN 4
      ELSE 5
    END
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 6. 테스트 쿼리
-- 브랜드가 있는지 먼저 확인
SELECT name, name_ko FROM brands LIMIT 5;

-- 브랜드 검색 테스트
SELECT * FROM search_brands('레페토');
SELECT * FROM search_brands('Repetto');

-- 상점 검색 테스트
SELECT * FROM search_all('레페토');
SELECT * FROM search_all('블로치');

-- 자동완성 테스트
SELECT * FROM suggest_brands('레', 5);
SELECT * FROM suggest_brands('Rep', 5);