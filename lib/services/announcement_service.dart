import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final _supabase = Supabase.instance.client;

  // Get all announcements for a shop (shop owner view)
  Future<List<Announcement>> getShopAnnouncements(String shopId) async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .eq('shop_id', shopId)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Announcement.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching shop announcements: $e');
      return [];
    }
  }

  // Get active announcements for a shop (public view)
  Future<List<Announcement>> getActiveAnnouncements(String shopId) async {
    try {
      final response = await _supabase
          .from('active_announcements')
          .select()
          .eq('shop_id', shopId);

      return (response as List)
          .map((json) => Announcement.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching active announcements: $e');
      return [];
    }
  }

  // Create a new announcement
  Future<Announcement?> createAnnouncement(Announcement announcement) async {
    try {
      final response = await _supabase
          .from('announcements')
          .insert(announcement.toInsertJson())
          .select()
          .single();

      return Announcement.fromJson(response);
    } catch (e) {
      print('Error creating announcement: $e');
      return null;
    }
  }

  // Update an existing announcement
  Future<bool> updateAnnouncement(String id, Announcement announcement) async {
    try {
      await _supabase
          .from('announcements')
          .update(announcement.toUpdateJson())
          .eq('id', id);

      return true;
    } catch (e) {
      print('Error updating announcement: $e');
      return false;
    }
  }

  // Delete an announcement
  Future<bool> deleteAnnouncement(String id) async {
    try {
      await _supabase
          .from('announcements')
          .delete()
          .eq('id', id);

      return true;
    } catch (e) {
      print('Error deleting announcement: $e');
      return false;
    }
  }

  // Toggle announcement active status
  Future<bool> toggleAnnouncementStatus(String id, bool isActive) async {
    try {
      await _supabase
          .from('announcements')
          .update({'is_active': isActive})
          .eq('id', id);

      return true;
    } catch (e) {
      print('Error toggling announcement status: $e');
      return false;
    }
  }

  // Toggle announcement pinned status
  Future<bool> toggleAnnouncementPin(String id, bool isPinned) async {
    try {
      await _supabase
          .from('announcements')
          .update({'is_pinned': isPinned})
          .eq('id', id);

      return true;
    } catch (e) {
      print('Error toggling announcement pin: $e');
      return false;
    }
  }

  // Get announcement by ID
  Future<Announcement?> getAnnouncement(String id) async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .eq('id', id)
          .single();

      return Announcement.fromJson(response);
    } catch (e) {
      print('Error fetching announcement: $e');
      return null;
    }
  }

  // Get announcement count for a shop
  Future<int> getAnnouncementCount(String shopId) async {
    try {
      final response = await _supabase
          .from('announcements')
          .select('id')
          .eq('shop_id', shopId)
          .eq('is_active', true)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error fetching announcement count: $e');
      return 0;
    }
  }

  // Check if shop has any active announcements
  Future<bool> hasActiveAnnouncements(String shopId) async {
    try {
      final count = await getAnnouncementCount(shopId);
      return count > 0;
    } catch (e) {
      print('Error checking active announcements: $e');
      return false;
    }
  }

  // Get pinned announcements
  Future<List<Announcement>> getPinnedAnnouncements(String shopId) async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .eq('shop_id', shopId)
          .eq('is_pinned', true)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Announcement.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching pinned announcements: $e');
      return [];
    }
  }

  // Batch update announcements (for bulk operations)
  Future<bool> batchUpdateAnnouncementStatus(
    List<String> ids,
    bool isActive,
  ) async {
    try {
      await _supabase
          .from('announcements')
          .update({'is_active': isActive})
          .inFilter('id', ids);

      return true;
    } catch (e) {
      print('Error batch updating announcements: $e');
      return false;
    }
  }
}