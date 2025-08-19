-- 컬럼명 충돌 문제를 해결한 함수들

-- 1. 기존 함수들 삭제
DROP FUNCTION IF EXISTS search_brands(text);
DROP FUNCTION IF EXISTS search_shops_by_brand(text);
DROP FUNCTION IF EXISTS search_all(text);
DROP FUNCTION IF EXISTS suggest_brands(text, integer);
DROP FUNCTION IF EXISTS simple_search(text);

-- 2. search_brands 함수 (수정 없음)
CREATE OR REPLACE FUNCTION search_brands(search_query TEXT)
RETURNS TABLE(
  brand_id UUID,
  brand_name TEXT,
  brand_name_ko TEXT,
  brand_logo_url TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT 
    b.id as brand_id, 
    b.name as brand_name, 
    b.name_ko as brand_name_ko, 
    b.logo_url as brand_logo_url
  FROM brands b
  WHERE 
    LOWER(b.name) LIKE LOWER('%' || search_query || '%')
    OR LOWER(COALESCE(b.name_ko, '')) LIKE LOWER('%' || search_query || '%')
    OR (
      b.search_keywords IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM unnest(b.search_keywords) AS keyword
        WHERE LOWER(keyword) LIKE LOWER('%' || search_query || '%')
      )
    );
END;
$$ LANGUAGE plpgsql;

-- 3. search_shops_by_brand 함수
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
    SELECT brand_id, brand_name FROM search_brands(search_query)
  )
  SELECT DISTINCT
    s.id as shop_id,
    s.name as shop_name,
    s.shop_type::TEXT as shop_type,
    s.description as shop_description,
    s.rating::FLOAT as shop_rating,
    array_agg(DISTINCT mb.brand_name) as matched_brands
  FROM shops s
  CROSS JOIN matched_brands mb
  WHERE mb.brand_name = ANY(s.brands)
  GROUP BY s.id, s.name, s.shop_type, s.description, s.rating;
END;
$$ LANGUAGE plpgsql;

-- 4. simple_search 함수 (컬럼명 명시)
CREATE OR REPLACE FUNCTION simple_search(query_text TEXT)
RETURNS TABLE(
  shop_id UUID,
  shop_name TEXT,
  shop_type TEXT,
  shop_description TEXT,
  shop_brands TEXT[],
  shop_rating FLOAT,
  shop_address TEXT,
  shop_website_url TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH brand_matched_shops AS (
    SELECT DISTINCT s.id as matched_shop_id
    FROM shops s, brands b
    WHERE b.name = ANY(s.brands)
    AND (
      LOWER(b.name) LIKE LOWER('%' || query_text || '%')
      OR LOWER(COALESCE(b.name_ko, '')) LIKE LOWER('%' || query_text || '%')
      OR (
        b.search_keywords IS NOT NULL AND
        EXISTS (
          SELECT 1 FROM unnest(b.search_keywords) AS keyword
          WHERE LOWER(keyword) LIKE LOWER('%' || query_text || '%')
        )
      )
    )
  )
  SELECT 
    s.id as shop_id,
    s.name as shop_name,
    s.shop_type::TEXT as shop_type,
    s.description as shop_description,
    s.brands as shop_brands,
    s.rating::FLOAT as shop_rating,
    s.address as shop_address,
    s.website_url as shop_website_url
  FROM shops s
  WHERE 
    LOWER(s.name) LIKE LOWER('%' || query_text || '%')
    OR LOWER(s.description) LIKE LOWER('%' || query_text || '%')
    OR s.id IN (SELECT matched_shop_id FROM brand_matched_shops)
  ORDER BY s.rating DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- 5. suggest_brands 자동완성 함수
CREATE OR REPLACE FUNCTION suggest_brands(search_query TEXT, limit_count INTEGER DEFAULT 10)
RETURNS TABLE(
  brand_id UUID,
  brand_name TEXT,
  brand_name_ko TEXT,
  display_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.id as brand_id,
    b.name as brand_name,
    b.name_ko as brand_name_ko,
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

-- 6. search_all 함수 (전체 검색)
CREATE OR REPLACE FUNCTION search_all(query_text TEXT)
RETURNS TABLE(
  shop_id UUID,
  shop_name TEXT,
  shop_type TEXT,
  shop_description TEXT,
  shop_brands TEXT[],
  shop_rating FLOAT,
  shop_review_count INTEGER,
  shop_image_url TEXT,
  shop_address TEXT,
  shop_phone TEXT,
  shop_latitude FLOAT,
  shop_longitude FLOAT,
  shop_website_url TEXT,
  search_relevance FLOAT
) AS $$
BEGIN
  RETURN QUERY
  WITH brand_matches AS (
    SELECT sb.shop_id, COUNT(*) as brand_match_count
    FROM search_shops_by_brand(query_text) sb
    GROUP BY sb.shop_id
  ),
  name_matches AS (
    SELECT 
      s.id as matched_id,
      CASE 
        WHEN LOWER(s.name) LIKE LOWER('%' || query_text || '%') THEN 3
        WHEN LOWER(s.description) LIKE LOWER('%' || query_text || '%') THEN 1
        ELSE 0
      END as name_match_score
    FROM shops s
  )
  SELECT 
    s.id as shop_id,
    s.name as shop_name,
    s.shop_type::TEXT as shop_type,
    s.description as shop_description,
    s.brands as shop_brands,
    s.rating::FLOAT as shop_rating,
    s.review_count as shop_review_count,
    s.image_url as shop_image_url,
    s.address as shop_address,
    s.phone as shop_phone,
    s.latitude::FLOAT as shop_latitude,
    s.longitude::FLOAT as shop_longitude,
    s.website_url as shop_website_url,
    (COALESCE(bm.brand_match_count, 0) * 5 + COALESCE(nm.name_match_score, 0))::FLOAT as search_relevance
  FROM shops s
  LEFT JOIN brand_matches bm ON bm.shop_id = s.id
  LEFT JOIN name_matches nm ON nm.matched_id = s.id
  WHERE 
    bm.shop_id IS NOT NULL 
    OR nm.name_match_score > 0
  ORDER BY search_relevance DESC, s.rating DESC;
END;
$$ LANGUAGE plpgsql;