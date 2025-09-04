# Supabase 스키마 최적화 계획

## 현재 상태 분석

### 1. 발견된 뷰 (Views)
분석 결과, 다음과 같은 뷰들이 여러 파일에서 중복 정의되어 있습니다:

#### 중복 정의된 뷰
- **shop_ratings**: 7개 파일에서 정의
- **reviews_with_user**: 6개 파일에서 정의  
- **shop_stats**: 3개 파일에서 정의
- **shop_details**: 2개 파일에서 정의
- **shops_with_main_brands**: 2개 파일에서 정의

### 2. 주요 함수 (Functions)
- `search_shops()`: 상점 검색
- `search_shops_by_brand()`: 브랜드별 검색
- `increment_shop_view()`: 조회수 증가
- `get_shop_stats()`: 상점 통계
- `update_updated_at()`: 타임스탬프 업데이트
- `is_shop_owner()`: 소유자 확인

### 3. 성능 이슈 가능성

#### 뷰 성능 문제
1. **shop_stats**: 여러 테이블 JOIN과 집계 함수
2. **shop_details**: ARRAY_AGG와 다중 LEFT JOIN
3. **reviews_with_replies**: 서브쿼리 사용

#### 인덱스 부재 가능성
- Foreign Key 컬럼에 인덱스 누락 가능
- 검색 빈도 높은 컬럼 인덱스 필요

## 최적화 계획

### Phase 1: 중복 제거 및 통합 (즉시 실행)

#### 1.1 통합 마이그레이션 파일 생성
```sql
-- 20250120_consolidated_schema.sql
-- 모든 중복 뷰와 함수를 하나의 파일로 통합
```

#### 1.2 제거 대상
- 오래된 마이그레이션 파일의 중복 정의
- 임시 수정 파일들 (quick_fix, alternative_solution 등)

### Phase 2: 성능 최적화

#### 2.1 인덱스 추가
```sql
-- 자주 조회되는 컬럼
CREATE INDEX idx_shops_owner_id ON shops(owner_id);
CREATE INDEX idx_reviews_shop_id ON reviews(shop_id);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);
CREATE INDEX idx_favorites_shop_id_user_id ON favorites(shop_id, user_id);
CREATE INDEX idx_shop_brands_shop_id ON shop_brands(shop_id);
CREATE INDEX idx_shop_brands_is_main ON shop_brands(is_main) WHERE is_main = true;
```

#### 2.2 뷰 최적화

**shop_stats 개선**
```sql
-- Materialized View 고려
CREATE MATERIALIZED VIEW shop_stats_mv AS
SELECT ... FROM shops ...;

-- 15분마다 자동 새로고침
CREATE OR REPLACE FUNCTION refresh_shop_stats_mv()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY shop_stats_mv;
END;
$$ LANGUAGE plpgsql;
```

**shop_details 개선**
```sql
-- 서브쿼리 대신 CTE 사용
WITH brand_data AS (
  SELECT shop_id, ARRAY_AGG(DISTINCT name) as brands
  FROM shop_brands JOIN brands ON ...
  GROUP BY shop_id
)
SELECT s.*, bd.brands
FROM shops s
LEFT JOIN brand_data bd ON s.id = bd.shop_id;
```

### Phase 3: 함수 최적화

#### 3.1 검색 함수 개선
```sql
-- 전문 검색 인덱스 추가
CREATE INDEX idx_shops_search ON shops 
USING gin(to_tsvector('korean', name || ' ' || COALESCE(description, '')));

-- 검색 함수 개선
CREATE OR REPLACE FUNCTION search_shops_optimized(
  search_term TEXT,
  limit_count INT DEFAULT 20
)
RETURNS TABLE(...) AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM shops
  WHERE to_tsvector('korean', name || ' ' || description) 
    @@ plainto_tsquery('korean', search_term)
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE;
```

### Phase 4: RLS 정책 최적화

#### 4.1 정책 단순화
- 복잡한 서브쿼리를 함수로 추출
- 자주 사용되는 권한 체크 캐싱

```sql
-- 권한 체크 함수 (STABLE로 캐싱 가능)
CREATE OR REPLACE FUNCTION can_manage_shop(shop_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM shops 
    WHERE id = shop_uuid 
    AND owner_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
```

### Phase 5: 모니터링 및 유지보수

#### 5.1 성능 모니터링 뷰
```sql
CREATE VIEW performance_metrics AS
SELECT 
  schemaname,
  tablename,
  n_live_tup as live_rows,
  n_dead_tup as dead_rows,
  last_vacuum,
  last_analyze
FROM pg_stat_user_tables
WHERE schemaname = 'public';
```

#### 5.2 자동 유지보수
- VACUUM 및 ANALYZE 스케줄링
- 통계 업데이트 자동화

## 실행 우선순위

1. **즉시 실행** (Critical)
   - SECURITY DEFINER 제거 (완료)
   - 중복 뷰/함수 통합

2. **단기 실행** (1주일 내)
   - 누락된 인덱스 추가
   - 기본 뷰 성능 개선

3. **중기 실행** (1개월 내)
   - Materialized View 도입
   - 검색 최적화

4. **장기 실행** (분기별)
   - 성능 모니터링 체계 구축
   - 정기적인 스키마 리뷰

## 예상 효과

- **쿼리 성능**: 30-50% 개선 예상
- **유지보수성**: 중복 제거로 관리 용이
- **확장성**: 인덱스 최적화로 대용량 처리 가능
- **보안**: RLS 정책 단순화로 보안 강화