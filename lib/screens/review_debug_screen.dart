import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';

class ReviewDebugScreen extends StatefulWidget {
  final String shopId;
  final String shopName;
  
  const ReviewDebugScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ReviewDebugScreen> createState() => _ReviewDebugScreenState();
}

class _ReviewDebugScreenState extends State<ReviewDebugScreen> {
  final _supabase = Supabase.instance.client;
  String _debugInfo = 'Loading...';
  
  @override
  void initState() {
    super.initState();
    _runDebugTests();
  }
  
  Future<void> _runDebugTests() async {
    final results = StringBuffer();
    
    try {
      // 1. 현재 사용자 확인
      final user = _supabase.auth.currentUser;
      results.writeln('=== 사용자 정보 ===');
      results.writeln('User ID: ${user?.id ?? "Not logged in"}');
      results.writeln('Email: ${user?.email ?? "N/A"}');
      results.writeln('');
      
      // 2. Shop ID 확인
      results.writeln('=== 상점 정보 ===');
      results.writeln('Shop ID: ${widget.shopId}');
      results.writeln('Shop Name: ${widget.shopName}');
      results.writeln('Shop ID Length: ${widget.shopId.length}');
      results.writeln('');
      
      // 3. reviews 테이블 직접 조회
      results.writeln('=== reviews 테이블 직접 조회 ===');
      try {
        final reviewsResponse = await _supabase
            .from('reviews')
            .select()
            .eq('shop_id', widget.shopId);
        
        results.writeln('✅ 리뷰 개수: ${(reviewsResponse as List).length}');
        if (reviewsResponse.isNotEmpty) {
          results.writeln('첫 번째 리뷰: ${reviewsResponse.first}');
        }
      } catch (e) {
        results.writeln('❌ Error: $e');
      }
      results.writeln('');
      
      // 4. shop_ratings 뷰 조회
      results.writeln('=== shop_ratings 뷰 조회 ===');
      try {
        final ratingsResponse = await _supabase
            .from('shop_ratings')
            .select()
            .eq('shop_id', widget.shopId)
            .maybeSingle();
        
        if (ratingsResponse != null) {
          results.writeln('✅ 평점 데이터: $ratingsResponse');
        } else {
          results.writeln('❌ 평점 데이터 없음');
        }
      } catch (e) {
        results.writeln('❌ Error: $e');
      }
      results.writeln('');
      
      // 5. reviews_with_user 뷰 조회
      results.writeln('=== reviews_with_user 뷰 조회 ===');
      try {
        final reviewsWithUserResponse = await _supabase
            .from('reviews_with_user')
            .select()
            .eq('shop_id', widget.shopId);
        
        results.writeln('✅ 리뷰 개수: ${(reviewsWithUserResponse as List).length}');
        if (reviewsWithUserResponse.isNotEmpty) {
          results.writeln('첫 번째 리뷰: ${reviewsWithUserResponse.first}');
        }
      } catch (e) {
        results.writeln('❌ Error: $e');
      }
      results.writeln('');
      
      // 6. 모든 shop_ratings 조회
      results.writeln('=== 모든 shop_ratings 조회 ===');
      try {
        final allRatingsResponse = await _supabase
            .from('shop_ratings')
            .select()
            .limit(5);
        
        results.writeln('✅ 전체 평점 데이터 개수: ${(allRatingsResponse as List).length}');
        for (final rating in allRatingsResponse) {
          results.writeln('Shop ID: ${rating['shop_id']}, Avg: ${rating['average_rating']}');
        }
      } catch (e) {
        results.writeln('❌ Error: $e');
      }
      results.writeln('');
      
      // 7. 테스트 리뷰 작성
      if (user != null) {
        results.writeln('=== 테스트 리뷰 작성 ===');
        try {
          // 기존 리뷰 삭제
          await _supabase
              .from('reviews')
              .delete()
              .eq('user_id', user.id)
              .eq('shop_id', widget.shopId);
          
          // 새 리뷰 작성
          await _supabase.from('reviews').insert({
            'user_id': user.id,
            'shop_id': widget.shopId,
            'rating': 5,
            'comment': 'Debug test review',
          });
          
          results.writeln('✅ 테스트 리뷰 작성 성공');
          
          // 작성 후 바로 조회
          final afterInsert = await _supabase
              .from('shop_ratings')
              .select()
              .eq('shop_id', widget.shopId)
              .maybeSingle();
          
          results.writeln('작성 후 평점: $afterInsert');
        } catch (e) {
          results.writeln('❌ Error: $e');
        }
      }
      
    } catch (e) {
      results.writeln('❌ 전체 오류: $e');
    }
    
    setState(() {
      _debugInfo = results.toString();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰 시스템 디버그'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDebugTests,
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
          child: SelectableText(
            _debugInfo,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}