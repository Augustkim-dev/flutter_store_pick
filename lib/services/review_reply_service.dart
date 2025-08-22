import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_reply.dart';
import '../models/review.dart';
import '../utils/app_logger.dart';

class ReviewReplyService {
  final _supabase = Supabase.instance.client;

  // Create a reply to a review
  Future<ReviewReply?> createReply({
    required String reviewId,
    required String shopId,
    required String content,
  }) async {
    try {
      // Check if reply already exists
      final existing = await getReplyForReview(reviewId);
      if (existing != null) {
        AppLogger.w('Reply already exists for this review');
        return null;
      }

      final response = await _supabase
          .from('review_replies')
          .insert({
            'review_id': reviewId,
            'shop_id': shopId,
            'content': content,
          })
          .select()
          .single();

      return ReviewReply.fromJson(response);
    } catch (e) {
      AppLogger.e('Error creating reply', e);
      return null;
    }
  }

  // Update an existing reply
  Future<bool> updateReply(String replyId, String content) async {
    try {
      await _supabase
          .from('review_replies')
          .update({'content': content})
          .eq('id', replyId);

      return true;
    } catch (e) {
      AppLogger.e('Error updating reply', e);
      return false;
    }
  }

  // Delete a reply
  Future<bool> deleteReply(String replyId) async {
    try {
      await _supabase
          .from('review_replies')
          .delete()
          .eq('id', replyId);

      return true;
    } catch (e) {
      AppLogger.e('Error deleting reply', e);
      return false;
    }
  }

  // Get reply for a specific review
  Future<ReviewReply?> getReplyForReview(String reviewId) async {
    try {
      final response = await _supabase
          .from('review_replies')
          .select()
          .eq('review_id', reviewId)
          .maybeSingle();

      if (response != null) {
        return ReviewReply.fromJson(response);
      }
      return null;
    } catch (e) {
      AppLogger.e('Error fetching reply', e);
      return null;
    }
  }

  // Get all replies for a shop
  Future<List<ReviewReply>> getShopReplies(String shopId) async {
    try {
      final response = await _supabase
          .from('review_replies')
          .select()
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ReviewReply.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching shop replies', e);
      return [];
    }
  }

  // Get reviews with replies for a shop
  Future<List<Review>> getShopReviewsWithReplies(String shopId) async {
    try {
      final response = await _supabase
          .from('reviews_with_replies')
          .select()
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Review.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching reviews with replies', e);
      return [];
    }
  }

  // Get unanswered reviews for a shop
  Future<List<Review>> getUnansweredReviews(String shopId) async {
    try {
      final response = await _supabase
          .from('reviews_with_replies')
          .select()
          .eq('shop_id', shopId)
          .isFilter('reply_id', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Review.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching unanswered reviews', e);
      return [];
    }
  }

  // Get reply statistics for a shop
  Future<Map<String, dynamic>> getReplyStats(String shopId) async {
    try {
      // Get total reviews
      final totalReviews = await _supabase
          .from('reviews')
          .select('id')
          .eq('shop_id', shopId)
          .count(CountOption.exact);

      // Get reviews with replies
      final repliedReviews = await _supabase
          .from('review_replies')
          .select('id')
          .eq('shop_id', shopId)
          .count(CountOption.exact);

      final total = totalReviews.count;
      final replied = repliedReviews.count;
      final unanswered = total - replied;
      final replyRate = total > 0 ? (replied / total * 100) : 0.0;

      return {
        'total_reviews': total,
        'replied_reviews': replied,
        'unanswered_reviews': unanswered,
        'reply_rate': replyRate,
      };
    } catch (e) {
      AppLogger.e('Error fetching reply stats', e);
      return {
        'total_reviews': 0,
        'replied_reviews': 0,
        'unanswered_reviews': 0,
        'reply_rate': 0.0,
      };
    }
  }

  // Check if current user can reply to a review
  Future<bool> canReplyToReview(String reviewId, String shopId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if user owns the shop
      final shop = await _supabase
          .from('shops')
          .select('owner_id')
          .eq('id', shopId)
          .single();

      if (shop['owner_id'] != userId) {
        return false;
      }

      // Check if reply already exists
      final existingReply = await getReplyForReview(reviewId);
      return existingReply == null;
    } catch (e) {
      AppLogger.e('Error checking reply permission', e);
      return false;
    }
  }

  // Get recent replies for dashboard
  Future<List<Map<String, dynamic>>> getRecentReplies(
    String shopId, {
    int limit = 5,
  }) async {
    try {
      final response = await _supabase
          .from('review_replies')
          .select('*, reviews!inner(rating, comment, user_id)')
          .eq('shop_id', shopId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('Error fetching recent replies', e);
      return [];
    }
  }

  // Batch check for unanswered reviews
  Future<List<String>> getUnansweredReviewIds(String shopId) async {
    try {
      final reviews = await _supabase
          .from('reviews')
          .select('id')
          .eq('shop_id', shopId);

      final replies = await _supabase
          .from('review_replies')
          .select('review_id')
          .eq('shop_id', shopId);

      final reviewIds = (reviews as List).map((r) => r['id'] as String).toSet();
      final repliedIds = (replies as List).map((r) => r['review_id'] as String).toSet();

      return reviewIds.difference(repliedIds).toList();
    } catch (e) {
      AppLogger.e('Error fetching unanswered review IDs', e);
      return [];
    }
  }
}