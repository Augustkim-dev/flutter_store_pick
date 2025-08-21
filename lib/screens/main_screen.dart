import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'map_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  
  // 각 탭의 화면을 캐싱하기 위한 Map
  final Map<int, Widget> _cachedScreens = {};
  
  // 각 탭의 Navigator Key를 유지
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];
  
  // 각 탭의 로드 상태를 추적
  final Set<int> _loadedTabs = {0}; // 홈 화면은 기본적으로 로드

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    
    if (kDebugMode) {
      print('🚀 MainScreen initialized with Lazy Loading');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final isFirstRouteInCurrentTab =
            !await _navigatorKeys[_currentIndex].currentState!.maybePop();
        if (isFirstRouteInCurrentTab) {
          if (_currentIndex != 0) {
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            // 앱 종료 처리
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: Scaffold(
        body: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // 스와이프 비활성화
          itemCount: 4,
          itemBuilder: (context, index) {
            // 한 번 로드된 화면은 캐싱하여 재사용
            if (_cachedScreens.containsKey(index)) {
              if (kDebugMode) {
                print('📱 Tab $index: Using cached screen');
              }
              return _cachedScreens[index]!;
            }
            
            // 처음 로드하는 화면
            if (kDebugMode) {
              print('🔄 Tab $index: Loading new screen');
            }
            
            Widget screen = _buildLazyScreen(index);
            _cachedScreens[index] = screen;
            _loadedTabs.add(index);
            
            return screen;
          },
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (kDebugMode) {
                print('🔸 Tab switched to: $index');
                print('🔸 Tab $index loaded: ${_loadedTabs.contains(index)}');
              }
              
              setState(() {
                _currentIndex = index;
              });
              
              // PageView를 해당 페이지로 이동
              _pageController.jumpToPage(index);
              
              // 메모리 사용량 로깅 (디버그 모드)
              if (kDebugMode) {
                print('📊 Loaded tabs: $_loadedTabs');
                print('📊 Cached screens: ${_cachedScreens.keys}');
              }
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: '검색',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: '지도',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: '마이페이지',
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Lazy Loading을 위한 화면 빌더
  Widget _buildLazyScreen(int index) {
    Widget screen;
    
    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const SearchScreen();
        break;
      case 2:
        screen = const MapScreen();
        break;
      case 3:
        screen = const ProfileScreen();
        break;
      default:
        screen = const HomeScreen();
    }
    
    // Navigator로 감싸서 각 탭에서 독립적인 네비게이션 스택 유지
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => screen,
        );
      },
    );
  }
}