# Supabase 최적화 완료 후 다음 단계

## ✅ 완료된 작업
1. **SECURITY DEFINER 보안 이슈 해결** (`20250120_fix_security_definer.sql`)
   - 모든 뷰에서 SECURITY DEFINER 제거
   - RLS 정책 준수하도록 수정

2. **스키마 최적화 완료** (`20250120_clean_optimized.sql`)
   - 중복 뷰/함수 통합
   - 인덱스 추가로 성능 개선
   - 간소화된 쿼리 구조

## 🚀 추천 다음 단계

### 1. 데이터베이스 정리 및 검증
```sql
-- 현재 활성 뷰 확인
SELECT viewname FROM pg_views WHERE schemaname = 'public';

-- 현재 활성 함수 확인
SELECT proname FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public';

-- 인덱스 사용 통계 확인
SELECT * FROM pg_stat_user_indexes WHERE schemaname = 'public';
```

### 2. 마이그레이션 파일 정리
불필요한 임시 파일 제거 대상:
- `quick_fix_*.sql`
- `alternative_solution.sql`
- `fix_*.sql` (완료된 수정 파일)
- 중복된 검색 함수 파일들

### 3. Flutter 앱 통합 테스트

#### 3.1 Supabase 클라이언트 업데이트 확인
```dart
// lib/services/supabase_service.dart
// 뷰와 함수 호출 부분 테스트

// 예시: shop_stats 뷰 사용
final stats = await supabase
  .from('shop_stats')
  .select()
  .eq('shop_id', shopId)
  .single();

// 예시: search_shops_by_brand 함수 사용
final result = await supabase
  .rpc('search_shops_by_brand', params: {
    'brand_name_search': searchTerm,
    'limit_count': 20
  });
```

#### 3.2 주요 기능 테스트 체크리스트
- [ ] 상점 목록 조회
- [ ] 상점 상세 정보 (shop_details 뷰)
- [ ] 리뷰 목록 (reviews_with_user 뷰)
- [ ] 상점 평점 (shop_ratings 뷰)
- [ ] 브랜드 검색 (search_shops_by_brand 함수)
- [ ] 조회수 증가 (increment_shop_view 함수)

### 4. 성능 모니터링 설정

#### 4.1 Supabase Dashboard에서 확인
- Query Performance 탭에서 느린 쿼리 확인
- Database Health 모니터링
- Index Usage 통계 확인

#### 4.2 커스텀 모니터링 쿼리
```sql
-- 테이블별 크기 확인
SELECT 
  relname AS table_name,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(relid) DESC;

-- 느린 쿼리 찾기
SELECT 
  query,
  calls,
  mean_exec_time,
  total_exec_time
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_%'
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### 5. 추가 최적화 기회

#### 5.1 Materialized View 도입 검토
자주 조회되지만 실시간성이 중요하지 않은 데이터:
- `shop_stats` - 15분 주기 새로고침
- 월별/주별 통계 집계

#### 5.2 파티셔닝 검토
대용량 테이블의 경우:
- `reviews` - 날짜별 파티셔닝
- `shop_views` - 월별 파티셔닝

#### 5.3 캐싱 전략
- Redis 도입 검토 (자주 조회되는 데이터)
- Edge Functions로 캐싱 레이어 구현

### 6. 문서화

#### 6.1 API 문서 업데이트
- 새로운 뷰와 함수 문서화
- 사용 예시 코드 추가

#### 6.2 개발자 가이드
- RLS 정책 설명
- 인덱스 전략
- 쿼리 최적화 팁

## 📋 Action Items

1. **즉시 실행**
   - [ ] Flutter 앱에서 통합 테스트
   - [ ] 불필요한 SQL 파일 백업 후 정리

2. **이번 주**
   - [ ] 성능 모니터링 대시보드 구성
   - [ ] 문서 업데이트

3. **다음 스프린트**
   - [ ] Materialized View 도입 검토
   - [ ] 추가 최적화 구현

## 🔍 주의사항

1. **프로덕션 배포 전**
   - 스테이징 환경에서 충분한 테스트
   - 백업 생성
   - 롤백 계획 수립

2. **모니터링**
   - 첫 주는 집중 모니터링
   - 쿼리 성능 변화 추적
   - 에러 로그 확인

3. **점진적 최적화**
   - 한 번에 모든 것을 변경하지 말 것
   - 측정 가능한 개선 목표 설정
   - A/B 테스트 고려