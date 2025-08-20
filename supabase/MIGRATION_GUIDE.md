# Supabase Migration Guide

## Shop Manager Phase 1 Database Migration

### 마이그레이션 실행 방법

1. **Supabase Dashboard 접속**
   - URL: https://supabase.com/dashboard/project/dzfkgfdwskbindpmlbum
   - 로그인 필요

2. **SQL Editor 열기**
   - 좌측 메뉴에서 "SQL Editor" 클릭
   - 또는 직접 링크: https://supabase.com/dashboard/project/dzfkgfdwskbindpmlbum/sql/new

3. **마이그레이션 SQL 실행**
   - `supabase/migrations/20250120_shop_manager_phase1.sql` 파일의 전체 내용을 복사
   - SQL Editor에 붙여넣기
   - "Run" 버튼 클릭

### 마이그레이션이 생성하는 항목들

#### 1. 테이블
- **review_replies**: 리뷰 답글 저장
- **announcements**: 공지사항 저장
- **shop_views**: 상점 조회수 추적

#### 2. 뷰 (Views)
- **shop_stats**: 상점 통계 집계
- **reviews_with_replies**: 리뷰와 답글 조인
- **active_announcements**: 활성 공지사항
- **shop_view_stats**: 조회수 통계

#### 3. 함수 (Functions)
- **update_updated_at_column()**: updated_at 자동 업데이트
- **increment_shop_view()**: 조회수 증가

#### 4. RLS 정책
- 각 테이블별 Row Level Security 정책
- 상점 소유자만 자신의 데이터 수정 가능
- 모든 사용자는 읽기 가능

### 마이그레이션 확인

SQL Editor에서 다음 쿼리로 테이블 생성 확인:

```sql
-- 테이블 확인
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('review_replies', 'announcements', 'shop_views');

-- 뷰 확인
SELECT table_name 
FROM information_schema.views 
WHERE table_schema = 'public' 
AND table_name IN ('shop_stats', 'reviews_with_replies', 'active_announcements', 'shop_view_stats');

-- RLS 정책 확인
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('review_replies', 'announcements', 'shop_views');
```

### 롤백 방법

문제가 발생한 경우 다음 SQL로 롤백:

```sql
-- Views
DROP VIEW IF EXISTS shop_view_stats CASCADE;
DROP VIEW IF EXISTS active_announcements CASCADE;
DROP VIEW IF EXISTS reviews_with_replies CASCADE;
DROP VIEW IF EXISTS shop_stats CASCADE;

-- Tables
DROP TABLE IF EXISTS shop_views CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS review_replies CASCADE;

-- Functions
DROP FUNCTION IF EXISTS increment_shop_view CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;
```

### 주의사항

1. **백업**: 프로덕션 환경에서는 실행 전 반드시 백업
2. **순서**: SQL 문장 순서대로 실행 (의존성 때문)
3. **권한**: 테이블 생성 권한이 있는 계정으로 실행
4. **RLS**: Row Level Security가 활성화되므로 정책 확인 필요

### 문제 해결

#### Error: relation "reviews" does not exist
- reviews 테이블이 먼저 생성되어 있어야 함
- 기본 스키마가 먼저 설정되었는지 확인

#### Error: permission denied
- Supabase Dashboard에서 실행하는지 확인
- Service role key가 아닌 anon key 사용 중인지 확인

#### Error: duplicate key value
- 이미 마이그레이션이 실행된 상태
- 롤백 후 다시 실행

### 테스트 데이터

마이그레이션 후 테스트 데이터 삽입:

```sql
-- 테스트 공지사항
INSERT INTO announcements (shop_id, title, content, is_pinned)
SELECT id, '신년 이벤트', '2025년 새해를 맞아 전 상품 10% 할인!', true
FROM shops LIMIT 1;

-- 테스트 리뷰 답글 (기존 리뷰가 있다면)
INSERT INTO review_replies (review_id, shop_id, content)
SELECT r.id, r.shop_id, '소중한 리뷰 감사합니다!'
FROM reviews r
LEFT JOIN review_replies rr ON r.id = rr.review_id
WHERE rr.id IS NULL
LIMIT 1;
```