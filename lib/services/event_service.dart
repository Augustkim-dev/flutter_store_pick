import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';
import '../utils/app_logger.dart';

class EventService {
  final _supabase = Supabase.instance.client;
  
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  // Cache for events
  List<Event>? _cachedActiveEvents;
  DateTime? _lastFetchTime;
  static const _cacheValidDuration = Duration(minutes: 5);

  bool get _isCacheValid {
    if (_cachedActiveEvents == null || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }

  void clearCache() {
    _cachedActiveEvents = null;
    _lastFetchTime = null;
  }

  // Get all active events (cached)
  Future<List<Event>> getActiveEvents({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cachedActiveEvents!;
    }

    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('events')
          .select('*, shops!inner(name, image_url, shop_type)')
          .eq('is_active', true)
          .lte('start_date', now)
          .gte('end_date', now)
          .order('is_featured', ascending: false)
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      final events = (response as List).map((json) {
        // Flatten shop data into event
        final eventData = Map<String, dynamic>.from(json);
        if (json['shops'] != null) {
          eventData['shop_name'] = json['shops']['name'];
          eventData['shop_image_url'] = json['shops']['image_url'];
          eventData['shop_type'] = json['shops']['shop_type'];
        }
        eventData.remove('shops');
        return Event.fromJson(eventData);
      }).toList();

      _cachedActiveEvents = events;
      _lastFetchTime = DateTime.now();
      
      return events;
    } catch (e) {
      AppLogger.e('Error fetching active events', e);
      return _cachedActiveEvents ?? [];
    }
  }

  // Get featured events for carousel
  Future<List<Event>> getFeaturedEvents() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('events')
          .select('*, shops!inner(name, image_url, shop_type)')
          .eq('is_active', true)
          .eq('is_featured', true)
          .lte('start_date', now)
          .gte('end_date', now)
          .order('priority', ascending: false)
          .limit(5);

      return (response as List).map((json) {
        final eventData = Map<String, dynamic>.from(json);
        if (json['shops'] != null) {
          eventData['shop_name'] = json['shops']['name'];
          eventData['shop_image_url'] = json['shops']['image_url'];
          eventData['shop_type'] = json['shops']['shop_type'];
        }
        eventData.remove('shops');
        return Event.fromJson(eventData);
      }).toList();
    } catch (e) {
      AppLogger.e('Error fetching featured events', e);
      return [];
    }
  }

  // Get upcoming events
  Future<List<Event>> getUpcomingEvents() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('events')
          .select('*, shops!inner(name, image_url, shop_type)')
          .eq('is_active', true)
          .gt('start_date', now)
          .order('start_date', ascending: true)
          .limit(10);

      return (response as List).map((json) {
        final eventData = Map<String, dynamic>.from(json);
        if (json['shops'] != null) {
          eventData['shop_name'] = json['shops']['name'];
          eventData['shop_image_url'] = json['shops']['image_url'];
          eventData['shop_type'] = json['shops']['shop_type'];
        }
        eventData.remove('shops');
        return Event.fromJson(eventData);
      }).toList();
    } catch (e) {
      AppLogger.e('Error fetching upcoming events', e);
      return [];
    }
  }

  // Get events for a specific shop
  Future<List<Event>> getShopEvents(String shopId) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('shop_id', shopId)
          .eq('is_active', true)
          .order('start_date', ascending: false);

      return (response as List)
          .map((json) => Event.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching shop events', e);
      return [];
    }
  }

  // Get a single event by ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final response = await _supabase
          .from('events')
          .select('*, shops!inner(name, image_url, shop_type)')
          .eq('id', eventId)
          .single();

      final eventData = Map<String, dynamic>.from(response);
      if (response['shops'] != null) {
        eventData['shop_name'] = response['shops']['name'];
        eventData['shop_image_url'] = response['shops']['image_url'];
        eventData['shop_type'] = response['shops']['shop_type'];
      }
      eventData.remove('shops');
      
      return Event.fromJson(eventData);
    } catch (e) {
      AppLogger.e('Error fetching event by ID', e);
      return null;
    }
  }

  // Create a new event (for shop owners)
  Future<Event?> createEvent(Event event) async {
    try {
      final response = await _supabase
          .from('events')
          .insert(event.toInsertJson())
          .select()
          .single();

      clearCache();
      return Event.fromJson(response);
    } catch (e) {
      AppLogger.e('Error creating event', e);
      return null;
    }
  }

  // Update an event
  Future<bool> updateEvent(String eventId, Event event) async {
    try {
      await _supabase
          .from('events')
          .update(event.toUpdateJson())
          .eq('id', eventId);

      clearCache();
      return true;
    } catch (e) {
      AppLogger.e('Error updating event', e);
      return false;
    }
  }

  // Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _supabase
          .from('events')
          .delete()
          .eq('id', eventId);

      clearCache();
      return true;
    } catch (e) {
      AppLogger.e('Error deleting event', e);
      return false;
    }
  }

  // Toggle event active status
  Future<bool> toggleEventStatus(String eventId, bool isActive) async {
    try {
      await _supabase
          .from('events')
          .update({'is_active': isActive})
          .eq('id', eventId);

      clearCache();
      return true;
    } catch (e) {
      AppLogger.e('Error toggling event status', e);
      return false;
    }
  }

  // Get event statistics
  Future<Map<String, dynamic>> getEventStats() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      // Count active events
      final activeCountResponse = await _supabase
          .from('events')
          .select('id')
          .eq('is_active', true)
          .lte('start_date', now)
          .gte('end_date', now);

      // Count upcoming events
      final upcomingCountResponse = await _supabase
          .from('events')
          .select('id')
          .eq('is_active', true)
          .gt('start_date', now);

      return {
        'activeCount': (activeCountResponse as List).length,
        'upcomingCount': (upcomingCountResponse as List).length,
        'totalCount': (activeCountResponse as List).length + (upcomingCountResponse as List).length,
      };
    } catch (e) {
      AppLogger.e('Error fetching event stats', e);
      return {
        'activeCount': 0,
        'upcomingCount': 0,
        'totalCount': 0,
      };
    }
  }
}