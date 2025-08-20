# Code Refactoring 01: 앱 시작 속도 및 성능 최적화

## 📋 개요
발레플러스 앱의 시작 속도가 느린 문제를 해결하고 전반적인 UI 렌더링 성능을 개선하기 위한 리팩토링 계획서입니다.

## 🎯 목표
- **앱 시작 시간 50% 단축** (현재 5-7초 → 목표 2-3초)
- **메인 화면 진입 시간 단축** (현재 3초 → 목표 1초 이내)
- **메모리 사용량 30% 감소**
- **부드러운 스크롤 및 화면 전환 구현** (60 FPS 유지)

## 🔍 현재 문제점 분석

### 1. 앱 초기화 병목 현상
- **문제**: Firebase, Supabase, NaverMap이 순차적으로 초기화
- **영향**: 각 서비스 초기화 시간이 누적되어 총 3-4초 소요
- **위치**: `lib/main.dart:16-72`

### 2. 스플래시 화면 지연
- **문제**: 불필요한 2초 강제 대기 + 동기적 Remote Config 페치
- **영향**: 스플래시 화면에서 최소 3초 이상 대기
- **위치**: `lib/screens/splash_screen.dart:80`

### 3. 메인 화면 과도한 초기 로딩
- **문제**: IndexedStack이 모든 탭 화면을 미리 생성
- **영향**: 메모리 과다 사용 및 초기 렌더링 지연
- **위치**: `lib/screens/main_screen.dart:46-54`

### 4. 데이터 로딩 비효율
- **문제**: 모든 상점 데이터를 한 번에 로드 + N+1 쿼리 문제
- **영향**: 네트워크 지연 및 UI 블로킹
- **위치**: `lib/screens/home_screen.dart:42-71`

## 📌 기존 최적화 현황

### 이미 구현된 최적화 (PERFORMANCE_OPTIMIZATION.md 참조)
- ✅ **CachedImageWidget**: 이미지 lazy loading 및 캐싱 구현 완료
- ✅ **PaginatedListView**: 20개씩 페이지네이션 구현 완료
- ✅ **SkeletonLoader**: 3종류 스켈레톤 로더 구현 완료
- ✅ **ErrorWidgetCustom**: 통합 에러 처리 위젯 구현 완료
- ✅ **SnackBarUtils**: 일관된 피드백 시스템 구현 완료

### 성능 개선 달성 지표
- 초기 로드: ~1.5초 (20개 상점)
- 추가 로드: ~0.5초 (페이지당)
- 썸네일 사용으로 메모리 사용량 70% 감소
- 60fps 스크롤 성능 유지

## 💡 추가 개선 계획

### Phase 1: 앱 초기화 최적화 (1일) - 최우선

#### 1.1 병렬 초기화 구현
```dart
// main.dart 개선안
Future<void> initializeServices() async {
  final futures = <Future>[];
  
  // Firebase 초기화
  futures.add(
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).catchError((e) {
      debugPrint('Firebase init failed: $e');
      return null;
    })
  );
  
  // Supabase 초기화 (선택적)
  futures.add(
    SupabaseService().initialize().catchError((e) {
      debugPrint('Supabase init failed: $e');
      return null;
    })
  );
  
  // NaverMap 초기화
  futures.add(
    FlutterNaverMap().init(
      clientId: AppConfig.naverMapClientId,
    ).catchError((e) {
      debugPrint('NaverMap init failed: $e');
      return null;
    })
  );
  
  // 병렬 실행
  await Future.wait(futures);
}
```

#### 1.2 스플래시 화면 최적화
```dart
// splash_screen.dart 개선안
Future<void> _checkVersionAndNavigate() async {
  // 버전 체크를 비동기로 처리
  final versionCheckFuture = _performVersionCheck();
  
  // 최소 표시 시간 (0.5초로 단축)
  final minDisplayFuture = Future.delayed(
    const Duration(milliseconds: 500)
  );
  
  // 둘 중 더 오래 걸리는 것 기다리기
  await Future.wait([versionCheckFuture, minDisplayFuture]);
  
  if (mounted) {
    Navigator.pushReplacementNamed(context, '/main');
  }
}
```

#### 1.3 Lazy Loading 탭 구현
```dart
// main_screen.dart 개선안
class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  final Map<int, Widget> _loadedPages = {};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          // 필요할 때만 페이지 생성
          _loadedPages[index] ??= _buildPage(index);
          return _loadedPages[index]!;
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
  
  Widget _buildPage(int index) {
    switch (index) {
      case 0: return const HomeScreen();
      case 1: return const SearchScreen();
      case 2: return const MapScreen();
      case 3: return const ProfileScreen();
      default: return const SizedBox();
    }
  }
}
```

### Phase 2: 데이터 로딩 추가 최적화 (2일)

#### 2.1 기존 페이지네이션 개선
**Note**: PaginatedListView는 이미 구현되어 있으므로, 기존 구현을 활용하여 개선
```dart
// home_screen.dart 개선안
class _HomeScreenState extends State<HomeScreen> {
  static const int _pageSize = 10;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final List<Shop> _shops = [];
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }
  
  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    
    try {
      // 첫 페이지만 로드
      final shops = await _shopService.getShops(
        page: 0, 
        pageSize: _pageSize
      );
      
      // 평점은 표시되는 상점만 가져오기
      final visibleShopIds = shops.take(3).map((s) => s.id).toList();
      final ratings = await _reviewService.getMultipleShopRatings(
        visibleShopIds
      );
      
      setState(() {
        _shops.addAll(shops);
        shopRatings = ratings;
        _hasMore = shops.length == _pageSize;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = '데이터 로드 실패';
        isLoading = false;
      });
    }
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }
  
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final shops = await _shopService.getShops(
        page: ++_currentPage,
        pageSize: _pageSize
      );
      
      setState(() {
        _shops.addAll(shops);
        _hasMore = shops.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }
}
```

#### 2.2 이미지 최적화 추가 개선
**Note**: CachedImageWidget이 이미 구현되어 있으므로, Transform API 활용 추가
```dart
// image_optimization_service.dart - Supabase Transform API 활용
class ImageOptimizationService {
  static String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    int quality = 80,
    String format = 'webp',
  }) {
    if (!originalUrl.contains('supabase')) return originalUrl;
    
    final params = <String, String>{};
    if (width != null) params['width'] = width.toString();
    if (height != null) params['height'] = height.toString();
    params['quality'] = quality.toString();
    params['format'] = format;
    
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    return '$originalUrl?$queryString';
  }
  
  // WebP 지원 체크 및 폴백
  static String getImageUrl(String url, BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 디바이스에 맞는 이미지 크기 계산
    final optimalWidth = (screenWidth * devicePixelRatio).toInt();
    
    return getOptimizedUrl(
      url,
      width: optimalWidth,
      quality: devicePixelRatio > 2 ? 85 : 75,
      format: _supportsWebP() ? 'webp' : 'jpg',
    );
  }
  
  static bool _supportsWebP() {
    // Platform 체크 로직
    return true; // 대부분의 최신 디바이스는 WebP 지원
  }
}
```

### Phase 3: 상태 관리 최적화 (2일)

#### 3.1 Provider 패턴 도입
```dart
// providers/app_provider.dart
class AppProvider extends ChangeNotifier {
  bool _isInitialized = false;
  List<Shop>? _cachedShops;
  DateTime? _lastFetchTime;
  
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await Future.wait([
      _initializeFirebase(),
      _initializeSupabase(),
      _initializeNaverMap(),
    ]);
    
    _isInitialized = true;
    notifyListeners();
  }
  
  List<Shop> getCachedShops() {
    // 5분 이내 캐시는 재사용
    if (_cachedShops != null && 
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < 
        const Duration(minutes: 5)) {
      return _cachedShops!;
    }
    return [];
  }
  
  void cacheShops(List<Shop> shops) {
    _cachedShops = shops;
    _lastFetchTime = DateTime.now();
    notifyListeners();
  }
}
```

#### 3.2 메모리 관리 개선
```dart
// utils/memory_manager.dart
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();
  
  Timer? _cleanupTimer;
  
  void startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => performCleanup(),
    );
  }
  
  void performCleanup() {
    // 이미지 캐시 정리
    imageCache.clear();
    imageCache.clearLiveImages();
    
    // 사용하지 않는 위젯 정리
    PaintingBinding.instance.imageCache.clear();
    
    // 가비지 컬렉션 힌트
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      SchedulerBinding.instance.ensureVisualUpdate();
    });
  }
  
  void dispose() {
    _cleanupTimer?.cancel();
  }
}
```

### Phase 4: 네트워크 최적화 (1일)

#### 4.1 API 호출 배치 처리
```dart
// services/batch_api_service.dart
class BatchApiService {
  final _pendingRequests = <String, Completer<dynamic>>{};
  Timer? _batchTimer;
  
  Future<T> batchRequest<T>(
    String key,
    Future<T> Function() request,
  ) async {
    // 이미 대기 중인 요청이 있으면 재사용
    if (_pendingRequests.containsKey(key)) {
      return await _pendingRequests[key]!.future as T;
    }
    
    final completer = Completer<T>();
    _pendingRequests[key] = completer;
    
    // 10ms 후 배치 실행
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(milliseconds: 10), () {
      _executeBatch();
    });
    
    return completer.future;
  }
  
  void _executeBatch() {
    final batch = Map<String, Completer<dynamic>>.from(_pendingRequests);
    _pendingRequests.clear();
    
    // 배치 실행
    for (final entry in batch.entries) {
      // 실제 요청 실행 로직
    }
  }
}
```

#### 4.2 HTTP 캐싱 구현
```dart
// services/http_cache_service.dart
class HttpCacheService {
  final _cache = <String, CachedResponse>{};
  
  Future<Response> get(
    String url, {
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    final cached = _cache[url];
    
    if (cached != null && !cached.isExpired) {
      return cached.response;
    }
    
    final response = await http.get(Uri.parse(url));
    
    _cache[url] = CachedResponse(
      response: response,
      expiry: DateTime.now().add(cacheDuration),
    );
    
    return response;
  }
}

class CachedResponse {
  final Response response;
  final DateTime expiry;
  
  CachedResponse({required this.response, required this.expiry});
  
  bool get isExpired => DateTime.now().isAfter(expiry);
}
```

### Phase 5: 추가 최적화 기법 (1일)

#### 5.1 코드 스플리팅 (Deferred Loading)
```dart
// 지연 로딩으로 초기 번들 크기 감소
import 'package:flutter_store_pick/screens/shop_detail_screen_v2.dart' 
  deferred as shop_detail;
import 'package:flutter_store_pick/screens/map_screen.dart' 
  deferred as map_screen;

// 사용 시점에 로드
Future<void> navigateToShopDetail(BuildContext context, Shop shop) async {
  await shop_detail.loadLibrary();
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => shop_detail.ShopDetailScreenV2(shop: shop),
    ),
  );
}
```

#### 5.2 RepaintBoundary 활용
```dart
// 애니메이션이나 자주 변경되는 위젯 최적화
class OptimizedShopCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        child: Column(
          children: [
            // 이미지는 별도 RepaintBoundary로 분리
            RepaintBoundary(
              child: CachedImageWidget(...),
            ),
            // 텍스트 영역
            ShopInfo(...),
          ],
        ),
      ),
    );
  }
}
```

#### 5.3 const 생성자 적극 활용
```dart
// 불필요한 리빌드 방지
class AppConstants {
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const BorderRadius defaultRadius = BorderRadius.all(Radius.circular(8.0));
  static const Duration animationDuration = Duration(milliseconds: 300);
}

// 사용 예시
Container(
  padding: AppConstants.defaultPadding, // const로 재사용
  decoration: const BoxDecoration(
    borderRadius: AppConstants.defaultRadius,
  ),
)
```

## 📊 예상 성능 개선 효과

| 메트릭 | 현재 | 기존 최적화 후 | 추가 개선 목표 | 총 개선율 |
|-------|------|--------------|--------------|----------|
| 앱 시작 시간 | 5-7초 | 3-4초 | 1.5-2초 | 70% ↓ |
| 메인 화면 진입 | 3초 | 1.5초 | 0.5-1초 | 80% ↓ |
| 메모리 사용량 | 150MB | 100MB | 70-80MB | 50% ↓ |
| FPS (스크롤) | 45 FPS | 60 FPS | 60 FPS 유지 | 33% ↑ |
| 네트워크 요청 | 20+ | 10-15 | 5-8 | 70% ↓ |
| 이미지 로딩 | 2-3초 | 1.5초 | 0.5-1초 | 75% ↓ |

## 🚀 구현 일정 (수정됨)

### Week 1 (즉시 적용 - 우선순위 높음)
- [ ] Day 1: **Phase 1** - 병렬 초기화, 스플래시 최적화 (앱 시작 속도 개선)
- [ ] Day 2: **Lazy Loading 탭** 구현 (메모리 사용량 감소)
- [ ] Day 3: **이미지 Transform API** 적용 (Supabase 최적화)
- [ ] Day 4: **코드 스플리팅** 및 const 최적화
- [ ] Day 5: 성능 측정 및 버그 수정

### Week 2 (추가 개선)
- [ ] Day 6-7: **Provider 패턴** 도입 (상태 관리 최적화)
- [ ] Day 8: **메모리 관리** 및 RepaintBoundary 적용
- [ ] Day 9: **네트워크 캐싱** 및 배치 처리
- [ ] Day 10: 통합 테스트 및 최종 성능 측정

### 기존 구현 활용
- ✅ PaginatedListView (이미 구현됨)
- ✅ CachedImageWidget (이미 구현됨)
- ✅ SkeletonLoader (이미 구현됨)
- ✅ ErrorWidgetCustom (이미 구현됨)

## 🧪 테스트 계획

### 성능 테스트
1. **앱 시작 시간 측정**
   - Cold Start: 앱 완전 종료 후 시작
   - Warm Start: 백그라운드에서 재시작
   
2. **메모리 프로파일링**
   - Flutter DevTools Memory 탭 활용
   - 메모리 누수 체크
   
3. **렌더링 성능**
   - Flutter Inspector Performance 탭
   - Jank 발생 구간 확인

### 사용자 테스트
1. **저사양 기기 테스트**
   - 2GB RAM 이하 기기
   - Android 7.0 / iOS 12 이상
   
2. **네트워크 환경 테스트**
   - 3G 환경 시뮬레이션
   - 오프라인 모드 전환

## 📝 주의사항

1. **하위 호환성 유지**
   - 기존 사용자 데이터 마이그레이션
   - API 버전 관리
   
2. **점진적 롤아웃**
   - A/B 테스트 적용
   - 단계별 배포
   
3. **모니터링**
   - Firebase Performance Monitoring 설정
   - Crashlytics 에러 트래킹

## 📈 성능 모니터링 도구

### 개발 중 사용
```dart
// utils/performance_monitor.dart
class PerformanceMonitor {
  static final _measurements = <String, List<int>>{};
  
  static void measureTime(String label, Function() task) {
    final stopwatch = Stopwatch()..start();
    task();
    stopwatch.stop();
    
    _measurements[label] ??= [];
    _measurements[label]!.add(stopwatch.elapsedMilliseconds);
    
    if (kDebugMode) {
      print('⏱️ $label: ${stopwatch.elapsedMilliseconds}ms');
    }
  }
  
  static void printReport() {
    if (!kDebugMode) return;
    
    print('\n📊 Performance Report:');
    _measurements.forEach((label, times) {
      final avg = times.reduce((a, b) => a + b) ~/ times.length;
      final min = times.reduce((a, b) => a < b ? a : b);
      final max = times.reduce((a, b) => a > b ? a : b);
      print('$label: avg=${avg}ms, min=${min}ms, max=${max}ms');
    });
  }
}

// 사용 예시
PerformanceMonitor.measureTime('Shop Loading', () async {
  await shopService.loadShops();
});
```

## 🔗 참고 자료

- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Dart Performance Tips](https://dart.dev/guides/language/effective-dart/usage#performance)
- [Firebase Performance Monitoring](https://firebase.google.com/docs/perf-mon)
- [기존 최적화 문서](./PERFORMANCE_OPTIMIZATION.md)

---

**작성일**: 2025-08-20  
**작성자**: Claude Code  
**버전**: 1.1.0 (PERFORMANCE_OPTIMIZATION.md 내용 통합)