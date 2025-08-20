# Ballet Plus 개발 가이드

## 🏗 프로젝트 구조

```
lib/
├── models/           # 데이터 모델
├── services/         # 비즈니스 로직 & API 통신
├── screens/          # 화면 위젯
│   └── shop/        # 상점 관련 화면
│       └── shop_edit_tabs/  # 상점 편집 탭들
├── widgets/          # 재사용 가능한 위젯
├── theme/           # 앱 테마 & 색상
├── utils/           # 유틸리티 함수
└── main.dart        # 앱 진입점
```

## 📱 주요 화면

### 1. HomeScreen
- 상점 목록 표시
- 고급 필터링 (유형, 편의시설, 인증)
- 스켈레톤 로더
- Pull to Refresh

### 2. ShopDetailScreenV2
- 5개 탭 구조 (기본정보/영업정보/브랜드/리뷰/공지)
- 이미지 갤러리
- 실시간 영업 상태
- 편의시설 표시

### 3. ShopEditScreenV2
- 5개 탭 구조 (기본/오프라인/온라인/브랜드/이미지)
- 30+ 필드 관리
- 이미지 업로드
- 실시간 유효성 검증

## 🔧 핵심 서비스

### ShopService
```dart
// 사용 예시
final shopService = ShopService();
shopService.setSupabaseMode(true);

// 상점 목록 조회
final shops = await shopService.getAllShops();

// 상점 정보 업데이트
await shopService.updateShop(updatedShop);
```

### ReviewService
```dart
// 리뷰 평점 조회
final rating = await reviewService.getShopRating(shopId);

// 리뷰 작성
await reviewService.createReview(review);
```

### ImageUploadService
```dart
// 메인 이미지 업로드
final url = await imageUploadService.uploadMainImage(
  shopId: shopId,
  imageFile: file,
);

// 갤러리 이미지 배치 업로드
final urls = await imageUploadService.uploadGalleryImages(
  shopId: shopId,
  imageFiles: files,
);
```

## 🎨 위젯 사용법

### 1. ShopCard
```dart
ShopCard(
  shop: shop,
  shopRating: rating,
  onTap: () => navigateToDetail(),
  searchQuery: searchText, // 하이라이트 표시
)
```

### 2. BusinessHoursWidget
```dart
BusinessHoursWidget(
  businessHours: hoursMap,
  closedDays: ['일요일'],
  onHoursChanged: (hours) => updateHours(hours),
  onClosedDaysChanged: (days) => updateClosedDays(days),
)
```

### 3. ShippingRegionWidget
```dart
ShippingRegionWidget(
  shopId: shopId,
  regions: shippingRegions,
  onRegionsChanged: (regions) => updateRegions(regions),
)
```

### 4. CachedImageWidget
```dart
CachedImageWidget(
  imageUrl: imageUrl,
  width: 200,
  height: 150,
  borderRadius: BorderRadius.circular(8),
  placeholder: SkeletonLoader(...),
)
```

### 5. PaginatedListView
```dart
PaginatedListView<Shop>(
  itemBuilder: (context, shop, index) => ShopCard(shop: shop),
  dataFetcher: (page, size) => loadShops(page, size),
  pageSize: 20,
  emptyWidget: EmptyStateWidget(...),
)
```

## 🔄 상태 관리

### 현재 방식 (setState)
```dart
class _MyScreenState extends State<MyScreen> {
  bool _isLoading = false;
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // 데이터 로드
    setState(() => _isLoading = false);
  }
}
```

### 향후 개선 (Provider/Riverpod 도입 예정)
```dart
// 예시
final shopsProvider = FutureProvider<List<Shop>>((ref) async {
  return ref.read(shopServiceProvider).getAllShops();
});
```

## 🎯 코딩 컨벤션

### 1. 네이밍 규칙
- **파일명**: snake_case (`shop_card.dart`)
- **클래스명**: PascalCase (`ShopCard`)
- **변수/함수**: camelCase (`shopName`, `loadShops()`)
- **상수**: UPPER_SNAKE_CASE 또는 camelCase
- **Private**: 언더스코어 prefix (`_privateMethod`)

### 2. 위젯 구조
```dart
class MyWidget extends StatefulWidget {
  // 1. 필수 파라미터
  final String requiredParam;
  
  // 2. 선택 파라미터
  final String? optionalParam;
  
  // 3. 콜백
  final VoidCallback? onTap;
  
  const MyWidget({
    Key? key,
    required this.requiredParam,
    this.optionalParam,
    this.onTap,
  }) : super(key: key);
}
```

### 3. 에러 처리
```dart
try {
  final result = await someAsyncOperation();
  // 성공 처리
  SnackBarUtils.showSuccess(context, '성공!');
} catch (e) {
  // 에러 처리
  SnackBarUtils.showError(context, '실패: $e');
}
```

## 🧪 테스트

### 유닛 테스트
```dart
test('Shop model serialization', () {
  final shop = Shop(name: 'Test Shop');
  final json = shop.toJson();
  expect(json['name'], 'Test Shop');
});
```

### 위젯 테스트
```dart
testWidgets('ShopCard displays shop name', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ShopCard(shop: testShop),
    ),
  );
  expect(find.text('Test Shop'), findsOneWidget);
});
```

## 📦 의존성

### 필수 패키지
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  image_picker: ^1.0.0
  fl_chart: ^0.65.0
```

### 개발 도구
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## 🚀 빌드 & 배포

### 개발 환경
```bash
flutter run
```

### 프로덕션 빌드
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 🐛 디버깅

### 로그 출력
```dart
if (kDebugMode) {
  print('Debug: $message');
}
```

### Flutter Inspector
- Widget Tree 분석
- Layout Explorer
- Performance Overlay

## 📝 주의사항

1. **Supabase 연동**: 항상 `setSupabaseMode(true)` 설정
2. **이미지 크기**: 5MB 이하, 1200x1200 권장
3. **리스트 성능**: 큰 리스트는 페이지네이션 필수
4. **에러 처리**: CustomErrorWidget 사용
5. **피드백**: SnackBarUtils 사용

## 🔗 관련 문서

- [PRD 문서](./store_pick_prd.md)
- [Phase 1-1 계획](./shop_manager_phase1_1.md)
- [성능 최적화 가이드](./PERFORMANCE_OPTIMIZATION.md)
- [변경 로그](./CHANGELOG.md)