import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('발레 용품점 찾기'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store,
              size: 80,
              color: AppColors.primaryAccent.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '홈 화면',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '상점 목록이 여기에 표시됩니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}