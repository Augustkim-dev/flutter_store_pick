import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';
import '../utils/app_logger.dart';

class ReviewService {
  final _supabase = Supabase.instance.client;
  
  // Supabase 모드 설정 (ShopService와 일관성을 위해)
  void setSupabaseMode(bool enabled) {
    // ReviewService는 항상 Supabase를 사용하므로 이 메서드는 비어있음
  }

  // 상점의 리뷰 목록 가져오기
  Future<List<Review>> getShopReviews(String shopId) async {
    try {
      final response = await _supabase
          .from('reviews_with_user')
          .select()
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Review.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching reviews', e);
      return [];
    }
  }

  // 사용자의 리뷰 목록 가져오기
  Future<List<Review>> getUserReviews(String userId) async {
    try {
      final response = await _supabase
          .from('reviews_with_user')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Review.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching user reviews', e);
      return [];
    }
  }

  // 특정 상점에 대한 사용자의 리뷰 가져오기
  Future<Review?> getUserReviewForShop(String userId, String shopId) async {
    try {
      final response = await _supabase
          .from('reviews_with_user')
          .select()
          .eq('user_id', userId)
          .eq('shop_id', shopId)
          .maybeSingle();

      if (response != null) {
        return Review.fromJson(response);
      }
      return null;
    } catch (e) {
      AppLogger.e('Error fetching user review', e);
      return null;
    }
  }

  // 리뷰 작성
  Future<bool> createReview({
    required String shopId,
    required int rating,
    String? comment,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        AppLogger.w('User not authenticated');
        return false;
      }

      // shop_id를 UUID 형식으로 전달 (shops 테이블의 id가 UUID 타입)
      await _supabase.from('reviews').insert({
        'user_id': user.id,
        'shop_id': shopId,  // shopId는 이미 UUID 문자열
        'rating': rating,
        'comment': comment,
      });

      return true;
    } catch (e) {
      AppLogger.e('Error creating review', e);
      return false;
    }
  }

  // 리뷰 수정
  Future<bool> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        AppLogger.w('User not authenticated');
        return false;
      }

      await _supabase
          .from('reviews')
          .update({
            'rating': rating,
            'comment': comment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      AppLogger.e('Error updating review', e);
      return false;
    }
  }

  // 리뷰 삭제
  Future<bool> deleteReview(String reviewId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        AppLogger.w('User not authenticated');
        return false;
      }

      await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      AppLogger.e('Error deleting review', e);
      return false;
    }
  }

  // 상점 평점 정보 가져오기
  Future<ShopRating?> getShopRating(String shopId) async {
    try {
      final response = await _supabase
          .from('shop_ratings')
          .select()
          .eq('shop_id', shopId)
          .maybeSingle();

      if (response != null) {
        return ShopRating.fromJson(response);
      }
      return null;
    } catch (e) {
      AppLogger.e('Error fetching shop rating', e);
      return null;
    }
  }

  // 여러 상점의 평점 정보 가져오기
  Future<Map<String, ShopRating>> getMultipleShopRatings(List<String> shopIds) async {
    try {
      if (shopIds.isEmpty) return {};

      final response = await _supabase
          .from('shop_ratings')
          .select()
          .inFilter('shop_id', shopIds);

      final ratings = <String, ShopRating>{};
      for (final json in response as List) {
        final rating = ShopRating.fromJson(json);
        ratings[rating.shopId] = rating;
      }
      return ratings;
    } catch (e) {
      AppLogger.e('Error fetching shop ratings', e);
      return {};
    }
  }
}