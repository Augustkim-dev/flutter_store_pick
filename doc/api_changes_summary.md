# API 변경 사항 요약

## DB 함수 반환 컬럼명 변경

### 1. search_brands 함수
이전:
```
id, name, name_ko, logo_url
```

변경 후:
```
brand_id, brand_name, brand_name_ko, brand_logo_url
```

### 2. search_shops_by_brand 함수
```
shop_id, shop_name, shop_type, shop_description, shop_rating, matched_brands
```

### 3. simple_search 함수
```
shop_id, shop_name, shop_type, shop_description, 
shop_brands, shop_rating, shop_address, shop_website_url
```

### 4. search_all 함수
```
shop_id, shop_name, shop_type, shop_description, shop_brands, 
shop_rating, shop_review_count, shop_image_url, shop_address, 
shop_phone, shop_latitude, shop_longitude, shop_website_url, search_relevance
```

### 5. suggest_brands 함수
```
brand_id, brand_name, brand_name_ko, display_name
```

## Flutter 서비스 변경 사항

### ShopService
1. **searchShops()** - search_all 함수 사용, 컬럼명 매핑 추가
2. **simpleSearchShops()** - simple_search 함수 사용 (새로 추가)

### BrandService  
1. **searchBrands()** - 컬럼명 매핑 추가
2. **suggestBrands()** - 컬럼명 매핑 추가

## 사용 예시

### 간단한 검색 (빠른 성능)
```dart
final shopService = ShopService();
shopService.setSupabaseMode(true);

// simple_search 사용
final shops = await shopService.simpleSearchShops('레페토');
```

### 고급 검색 (관련도 점수 포함)
```dart
// search_all 사용
final shops = await shopService.searchShops('레페토');
```

### 브랜드 자동완성
```dart
final brandService = BrandService();

// 자동완성 제안
final suggestions = await brandService.suggestBrands('레', limit: 5);
// suggestions 예시:
// [
//   {'id': '...', 'name': 'Repetto', 'name_ko': '레페토', 'display_name': 'Repetto (레페토)'},
//   ...
// ]
```

## 검색 가능한 브랜드 목록

| 한글 검색어 | 매칭되는 브랜드 |
|------------|----------------|
| 레페토, 레파토 | Repetto |
| 가리뇽, 가이너 | Gaynor Minden |
| 그리쉬코, 그리시코 | Grishko |
| 블로치, 블로흐 | Bloch |
| 카펠리오, 카페지오 | Capezio |
| 산샤, 산사 | Sansha |
| 웨어무아, 웨어모아 | Wear Moi |
| 샤넬 | Chanel |
| 댄스코, 단스코 | Dansco |
| 프리드 | Freed of London |
| 러시안포인트 | Russian Pointe |
| 서포크, 서폭 | Suffolk |
| 소단사, 소댄사 | So Danca |
| 미렐라 | Mirella |
| 바디래퍼스 | Body Wrappers |