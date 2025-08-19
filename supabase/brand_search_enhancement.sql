-- 한글-영어 브랜드 검색 기능 구현
-- Phase: 브랜드 검색 개선

-- 1. brands 테이블 스키마 확장
ALTER TABLE brands 
ADD COLUMN IF NOT EXISTS name_ko TEXT,
ADD COLUMN IF NOT EXISTS search_keywords TEXT[];

-- 2. 인덱스 추가 (검색 성능 향상)
CREATE INDEX IF NOT EXISTS idx_brands_name_ko ON brands(name_ko);
CREATE INDEX IF NOT EXISTS idx_brands_search ON brands USING GIN(search_keywords);

-- 3. 브랜드 데이터 업데이트 (한글명 및 검색 키워드)
-- Repetto
UPDATE brands SET 
  name_ko = '레페토',
  search_keywords = ARRAY['레페토', '레파토', 'repetto', 'lepetto', 'REPETTO']
WHERE LOWER(name) = 'repetto';

-- Gaynor Minden
UPDATE brands SET 
  name_ko = '가리뇽 민든',
  search_keywords = ARRAY['가리뇽', '가이너', '게이너', '가이너민든', 'gaynor', 'gaynor minden', 'GAYNOR MINDEN']
WHERE LOWER(name) = 'gaynor minden';

-- Grishko
UPDATE brands SET 
  name_ko = '그리쉬코',
  search_keywords = ARRAY['그리쉬코', '그리시코', 'grishko', 'GRISHKO']
WHERE LOWER(name) = 'grishko';

-- Bloch
UPDATE brands SET 
  name_ko = '블로치',
  search_keywords = ARRAY['블로치', '블로흐', 'bloch', 'BLOCH']
WHERE LOWER(name) = 'bloch';

-- Capezio
UPDATE brands SET 
  name_ko = '카펠리오',
  search_keywords = ARRAY['카펠리오', '카페지오', '카페치오', 'capezio', 'CAPEZIO']
WHERE LOWER(name) = 'capezio';

-- Sansha
UPDATE brands SET 
  name_ko = '산샤',
  search_keywords = ARRAY['산샤', '산사', 'sansha', 'SANSHA']
WHERE LOWER(name) = 'sansha';

-- Wear Moi
UPDATE brands SET 
  name_ko = '웨어무아',
  search_keywords = ARRAY['웨어무아', '웨어모아', '웨어모이', 'wear moi', 'wearmoi', 'WEAR MOI']
WHERE LOWER(name) = 'wear moi';

-- Chanel (for general fashion/accessories)
UPDATE brands SET 
  name_ko = '샤넬',
  search_keywords = ARRAY['샤넬', 'chanel', 'CHANEL']
WHERE LOWER(name) = 'chanel';

-- Dansco
UPDATE brands SET 
  name_ko = '댄스코',
  search_keywords = ARRAY['댄스코', '단스코', 'dansco', 'DANSCO']
WHERE LOWER(name) = 'dansco';

-- Freed of London
UPDATE brands SET 
  name_ko = '프리드',
  search_keywords = ARRAY['프리드', '프리드오브런던', 'freed', 'freed of london', 'FREED']
WHERE LOWER(name) = 'freed of london' OR LOWER(name) = 'freed';

-- Russian Pointe
UPDATE brands SET 
  name_ko = '러시안포인트',
  search_keywords = ARRAY['러시안포인트', '러시안포인테', 'russian pointe', 'RUSSIAN POINTE']
WHERE LOWER(name) = 'russian pointe';

-- Suffolk
UPDATE brands SET 
  name_ko = '서포크',
  search_keywords = ARRAY['서포크', '서폭', 'suffolk', 'SUFFOLK']
WHERE LOWER(name) = 'suffolk';

-- So Danca
UPDATE brands SET 
  name_ko = '소단사',
  search_keywords = ARRAY['소단사', '소댄사', 'so danca', 'sodanca', 'SO DANCA']
WHERE LOWER(name) = 'so danca';

-- Mirella
UPDATE brands SET 
  name_ko = '미렐라',
  search_keywords = ARRAY['미렐라', '미렐라', 'mirella', 'MIRELLA']
WHERE LOWER(name) = 'mirella';

-- Body Wrappers
UPDATE brands SET 
  name_ko = '바디래퍼스',
  search_keywords = ARRAY['바디래퍼스', '바디래퍼', 'body wrappers', 'bodywrappers', 'BODY WRAPPERS']
WHERE LOWER(name) = 'body wrappers';

-- 4. 브랜드 검색 함수
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
    OR LOWER(b.name_ko) LIKE LOWER('%' || search_query || '%')
    -- 검색 키워드 배열 검색
    OR EXISTS (
      SELECT 1 FROM unnest(b.search_keywords) AS keyword
      WHERE LOWER(keyword) LIKE LOWER('%' || search_query || '%')
    );
END;
$$ LANGUAGE plpgsql;

-- 5. 브랜드명으로 상점 검색 함수
CREATE OR REPLACE FUNCTION search_shops_by_brand(search_query TEXT)
RETURNS TABLE(
  shop_id UUID,
  shop_name TEXT,
  shop_type shop_type,
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
    s.shop_type,
    s.description as shop_description,
    s.rating as shop_rating,
    array_agg(DISTINCT mb.name) as matched_brands
  FROM shops s
  CROSS JOIN matched_brands mb
  WHERE mb.name = ANY(s.brands)
  GROUP BY s.id, s.name, s.shop_type, s.description, s.rating;
END;
$$ LANGUAGE plpgsql;

-- 6. 통합 검색 함수 (상점명, 설명, 브랜드 모두 검색)
CREATE OR REPLACE FUNCTION search_all(query_text TEXT)
RETURNS TABLE(
  id UUID,
  name TEXT,
  shop_type shop_type,
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
    s.shop_type,
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

-- 7. 브랜드 자동완성 함수 (옵션)
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
    OR LOWER(b.name_ko) LIKE LOWER(search_query || '%')
    OR EXISTS (
      SELECT 1 FROM unnest(b.search_keywords) AS keyword
      WHERE LOWER(keyword) LIKE LOWER(search_query || '%')
    )
  ORDER BY 
    CASE 
      WHEN LOWER(b.name) = LOWER(search_query) THEN 1
      WHEN LOWER(b.name_ko) = LOWER(search_query) THEN 2
      WHEN LOWER(b.name) LIKE LOWER(search_query || '%') THEN 3
      WHEN LOWER(b.name_ko) LIKE LOWER(search_query || '%') THEN 4
      ELSE 5
    END
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 8. 테스트 쿼리
-- 브랜드 검색 테스트
SELECT * FROM search_brands('레페토');
SELECT * FROM search_brands('repetto');
SELECT * FROM search_brands('가리뇽');

-- 상점 검색 테스트
SELECT * FROM search_all('레페토');
SELECT * FROM search_all('블로치');

-- 자동완성 테스트
SELECT * FROM suggest_brands('레', 5);
SELECT * FROM suggest_brands('rep', 5);