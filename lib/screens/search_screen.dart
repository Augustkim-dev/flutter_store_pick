import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 검색바 플레이스홀더
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.gray,
                ),
                const SizedBox(width: 12),
                Text(
                  '상점 또는 브랜드 검색',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
          
          // 중앙 플레이스홀더
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 80,
                    color: AppColors.secondaryAccent.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '검색 화면',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '원하는 상점이나 브랜드를 검색해보세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}