import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 성능 측정을 위한 시작 시간 기록
  final stopwatch = Stopwatch()..start();
  
  // 설정 검증 (병렬 처리 전에 실행)
  try {
    AppConfig.validateConfig();
  } catch (e) {
    if (kDebugMode) {
      print('Configuration error: $e');
    }
  }

  // 모든 서비스를 병렬로 초기화
  final List<Future<void>> initFutures = [];
  
  // Firebase 초기화
  initFutures.add(
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((_) {
      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
      }
    }).catchError((e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Firebase: $e');
      }
      return null;
    })
  );

  // 네이버 지도 초기화
  initFutures.add(
    FlutterNaverMap().init(
      clientId: AppConfig.naverMapClientId,
      onAuthFailed: (ex) {
        if (kDebugMode) {
          switch (ex) {
            case NQuotaExceededException(:final message):
              AppConfig.debugPrint("사용량 초과 (message: $message)");
              break;
            case NUnauthorizedClientException() ||
                 NClientUnspecifiedException() ||
                 NAnotherAuthFailedException():
              AppConfig.debugPrint("인증 실패: $ex");
              break;
          }
        }
      },
    ).then((_) {
      if (kDebugMode) {
        print('✅ Naver Map initialized successfully');
      }
    }).catchError((e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Naver Map: $e');
      }
      return null;
    })
  );

  // Supabase 초기화 (실패해도 앱은 실행됨)
  initFutures.add(
    SupabaseService().initialize().then((_) {
      if (kDebugMode) {
        print('✅ Supabase initialized successfully');
      }
    }).catchError((e) {
      if (kDebugMode) {
        print('⚠️ Failed to initialize Supabase: $e');
        print('ℹ️ App will run with dummy data');
      }
      return null;
    })
  );

  // 모든 초기화 작업을 병렬로 실행
  await Future.wait(initFutures);
  
  stopwatch.stop();
  if (kDebugMode) {
    print('🚀 App initialization completed in ${stopwatch.elapsedMilliseconds}ms');
  }

  runApp(const BalletShopApp());
}

class BalletShopApp extends StatelessWidget {
  const BalletShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '발레 용품점 찾기',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {'/': (context) => const SplashScreen(), '/main': (context) => const MainScreen()},
    );
  }
}
