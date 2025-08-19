-- 검색 함수 수정 (shop_type 타입 문제 해결)

-- 1. 먼저 기존 함수들을 삭제
DROP FUNCTION IF EXISTS search_all(text);
DROP FUNCTION IF EXISTS search_shops_by_brand(text);

-- 2. search_shops_by_brand 함수 재생성 (shop_type을 TEXT로 캐스팅)
CREATE OR REPLACE FUNCTION search_shops_by_brand(search_query TEXT)
RETURNS TABLE(
  shop_id UUID,
  shop_name TEXT,
  shop_type TEXT,  -- shop_type enum을 TEXT로 변경
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
    s.shop_type::TEXT as shop_type,  -- enum을 TEXT로 캐스팅
    s.description as shop_description,
    s.rating as shop_rating,
    array_agg(DISTINCT mb.name) as matched_brands
  FROM shops s
  CROSS JOIN matched_brands mb
  WHERE mb.name = ANY(s.brands)
  GROUP BY s.id, s.name, s.shop_type, s.description, s.rating;
END;
$$ LANGUAGE plpgsql;

-- 3. search_all 함수 재생성 (shop_type을 TEXT로 반환)
CREATE OR REPLACE FUNCTION search_all(query_text TEXT)
RETURNS TABLE(
  id UUID,
  name TEXT,
  shop_type TEXT,  -- shop_type enum을 TEXT로 변경
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
    s.shop_type::TEXT,  -- enum을 TEXT로 캐스팅
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

-- 4. 테스트 쿼리
-- 브랜드 검색 테스트
SELECT * FROM search_brands('레페토');
SELECT * FROM search_brands('repetto');

-- 상점 검색 테스트
SELECT * FROM search_all('레페토');
SELECT * FROM search_all('블로치');
SELECT * FROM search_all('가리뇽');

-- 자동완성 테스트
SELECT * FROM suggest_brands('레', 5);
SELECT * FROM suggest_brands('rep', 5);