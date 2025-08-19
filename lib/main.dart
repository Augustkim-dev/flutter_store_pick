import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 설정 검증
  try {
    AppConfig.validateConfig();
  } catch (e) {
    if (kDebugMode) {
      print('Configuration error: $e');
    }
  }

  // 네이버 지도 초기화
  await FlutterNaverMap().init(
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
  );
  
  if (kDebugMode) {
    print('Naver Map initialized successfully');
  }

  // Supabase 초기화 시도 (실패해도 앱은 실행됨)
  try {
    await SupabaseService().initialize();
    if (kDebugMode) {
      print('Supabase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Failed to initialize Supabase: $e');
      print('App will run with dummy data');
    }
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
