import 'package:flutter/material.dart';
import '../services/review_service.dart';
import '../services/shop_service.dart';
import '../theme/app_colors.dart';

class ReviewTestScreen extends StatefulWidget {
  const ReviewTestScreen({super.key});

  @override
  State<ReviewTestScreen> createState() => _ReviewTestScreenState();
}

class _ReviewTestScreenState extends State<ReviewTestScreen> {
  final _reviewService = ReviewService();
  final _shopService = ShopService();
  String _testResults = 'Testing...';

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    final results = StringBuffer();
    
    try {
      // 1. 상점 목록 가져오기
      results.writeln('=== 상점 목록 테스트 ===');
      final shops = await _shopService.getAllShops();
      results.writeln('✅ 상점 개수: ${shops.length}');
      
      if (shops.isNotEmpty) {
        final firstShop = shops.first;
        results.writeln('첫 번째 상점: ${firstShop.name}');
        
        // 2. 해당 상점의 리뷰 가져오기
        results.writeln('\n=== 리뷰 조회 테스트 ===');
        final reviews = await _reviewService.getShopReviews(firstShop.id);
        results.writeln('✅ 리뷰 개수: ${reviews.length}');
        
        if (reviews.isNotEmpty) {
          results.writeln('첫 번째 리뷰 평점: ${reviews.first.rating}');
          results.writeln('리뷰 작성자: ${reviews.first.userName ?? "익명"}');
        }
        
        // 3. 평점 정보 가져오기
        results.writeln('\n=== 평점 정보 테스트 ===');
        final rating = await _reviewService.getShopRating(firstShop.id);
        if (rating != null) {
          results.writeln('✅ 평균 평점: ${rating.averageRating}');
          results.writeln('✅ 총 리뷰 수: ${rating.reviewCount}');
          results.writeln('✅ 5점: ${rating.fiveStarCount}개');
          results.writeln('✅ 4점: ${rating.fourStarCount}개');
          results.writeln('✅ 3점: ${rating.threeStarCount}개');
          results.writeln('✅ 2점: ${rating.twoStarCount}개');
          results.writeln('✅ 1점: ${rating.oneStarCount}개');
        } else {
          results.writeln('❌ 평점 정보를 가져올 수 없음');
        }
        
        // 4. 여러 상점의 평점 정보 한 번에 가져오기
        results.writeln('\n=== 다중 평점 조회 테스트 ===');
        final shopIds = shops.take(3).map((s) => s.id).toList();
        final ratings = await _reviewService.getMultipleShopRatings(shopIds);
        results.writeln('✅ 조회된 평점 정보 개수: ${ratings.length}');
        
        ratings.forEach((shopId, rating) {
          final shop = shops.firstWhere((s) => s.id == shopId);
          results.writeln('${shop.name}: ${rating.averageRating} (${rating.reviewCount}개)');
        });
      }
      
    } catch (e) {
      results.writeln('\n❌ 오류 발생: $e');
    }
    
    setState(() {
      _testResults = results.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰 시스템 테스트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runTests,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _testResults,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}