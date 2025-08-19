# 한글-영어 브랜드 검색 기능 가이드

## 개요
사용자가 브랜드를 한글 또는 영어로 검색할 수 있는 통합 검색 기능입니다.
예를 들어 "레페토"로 검색하면 "Repetto" 브랜드를 취급하는 상점들이 검색됩니다.

## 구현 내용

### 1. 데이터베이스 변경사항
- `brands` 테이블에 `name_ko` (한글명) 컬럼 추가
- `brands` 테이블에 `search_keywords` (검색 키워드 배열) 컬럼 추가
- 검색 성능을 위한 인덱스 추가

### 2. 지원 브랜드 매핑
| 영어명 | 한글명 | 검색 가능한 키워드 |
|--------|--------|-------------------|
| Repetto | 레페토 | 레페토, 레파토 |
| Gaynor Minden | 가리뇽 민든 | 가리뇽, 가이너, 게이너, 가이너민든 |
| Grishko | 그리쉬코 | 그리쉬코, 그리시코 |
| Bloch | 블로치 | 블로치, 블로흐 |
| Capezio | 카펠리오 | 카펠리오, 카페지오, 카페치오 |
| Sansha | 산샤 | 산샤, 산사 |
| Wear Moi | 웨어무아 | 웨어무아, 웨어모아, 웨어모이 |
| Chanel | 샤넬 | 샤넬 |
| Dansco | 댄스코 | 댄스코, 단스코 |
| Freed of London | 프리드 | 프리드, 프리드오브런던 |
| Russian Pointe | 러시안포인트 | 러시안포인트, 러시안포인테 |
| Suffolk | 서포크 | 서포크, 서폭 |
| So Danca | 소단사 | 소단사, 소댄사 |
| Mirella | 미렐라 | 미렐라 |
| Body Wrappers | 바디래퍼스 | 바디래퍼스, 바디래퍼 |

### 3. SQL 함수
- `search_brands(search_query)`: 브랜드 검색
- `search_shops_by_brand(search_query)`: 브랜드로 상점 검색
- `search_all(query_text)`: 통합 검색 (상점명, 설명, 브랜드)
- `suggest_brands(search_query, limit_count)`: 브랜드 자동완성

### 4. Flutter 서비스
- `ShopService.searchShops()`: RPC 함수를 사용한 통합 검색
- `BrandService`: 브랜드 검색 및 자동완성 서비스

## 설치 방법

### 1. Supabase SQL 실행
```sql
-- Supabase SQL Editor에서 실행
-- supabase/brand_search_enhancement.sql 파일 내용 전체 실행
```

### 2. Flutter 앱 업데이트
```dart
// 검색 사용 예시
final shopService = ShopService();
shopService.setSupabaseMode(true);

// 한글로 검색
final shops1 = await shopService.searchShops('레페토');

// 영어로 검색
final shops2 = await shopService.searchShops('Repetto');

// 브랜드 자동완성
final brandService = BrandService();
final suggestions = await brandService.suggestBrands('레', limit: 5);
```

## 테스트 방법

### 1. SQL 테스트
```sql
-- 브랜드 검색 테스트
SELECT * FROM search_brands('레페토');
SELECT * FROM search_brands('repetto');

-- 상점 검색 테스트
SELECT * FROM search_all('레페토');
SELECT * FROM search_all('가리뇽');

-- 자동완성 테스트
SELECT * FROM suggest_brands('레', 5);
```

### 2. Flutter 앱 테스트
1. 검색 화면에서 "레페토" 입력
2. Repetto 브랜드를 취급하는 상점들이 표시되는지 확인
3. "가리뇽" 입력
4. Gaynor Minden 브랜드를 취급하는 상점들이 표시되는지 확인

## 추가 개선 가능 사항

1. **더 많은 브랜드 추가**
   - 새로운 브랜드의 한글명과 검색 키워드를 brands 테이블에 추가

2. **Fuzzy Search 구현**
   - PostgreSQL의 pg_trgm extension 사용
   - 오타 허용 검색 구현

3. **검색 로그 수집**
   - 사용자 검색 패턴 분석
   - 인기 검색어 기반 추천

4. **검색 UI 개선**
   - 실시간 자동완성
   - 최근 검색어 저장
   - 인기 검색어 표시

## 주의사항
- brands 테이블의 name 필드는 대소문자를 정확히 맞춰야 함
- search_keywords 배열에는 다양한 변형을 포함시킬 것
- 새 브랜드 추가 시 한글명과 검색 키워드를 함께 등록