import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() {
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
      routes: {
        '/': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
