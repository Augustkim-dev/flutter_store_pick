import 'dart:async';
import '../models/shop.dart';
import '../models/event.dart';
import '../models/announcement.dart';
import '../models/review.dart';
import 'shop_service.dart';
import 'event_service.dart';
import 'announcement_service.dart';
import 'review_service.dart';
import 'favorite_service.dart';
import '../utils/app_logger.dart';

class DashboardData {
  final List<Event> featuredEvents;
  final List<Shop> newShops;
  final List<Shop> popularShops;
  final List<Announcement> recentAnnouncements;
  final List<Shop> favoriteShops;
  final DashboardStats stats;
  final bool isLoadingComplete;  // 전체 로딩 완료 여부
  final Map<String, bool> sectionLoadingStatus;  // 각 섹션별 로딩 상태
  
  DashboardData({
    required this.featuredEvents,
    required this.newShops,
    required this.popularShops,
    required this.recentAnnouncements,
    required this.favoriteShops,
    required this.stats,
    this.isLoadingComplete = false,
    Map<String, bool>? sectionLoadingStatus,
  }) : sectionLoadingStatus = sectionLoadingStatus ?? {
    'stats': false,
    'events': false,
    'announcements': false,
    'newShops': false,
    'popularShops': false,
    'favoriteShops': false,
  };
}

class DashboardStats {
  final int totalShops;
  final int activeEvents;
  final int weeklyReviews;
  final int totalAnnouncements;
  
  DashboardStats({
    required this.totalShops,
    required this.activeEvents,
    required this.weeklyReviews,
    required this.totalAnnouncements,
  });
}

class DashboardService {
  final ShopService _shopService = ShopService();
  final EventService _eventService = EventService();
  final AnnouncementService _announcementService = AnnouncementService();
  final ReviewService _reviewService = ReviewService();
  final FavoriteService _favoriteService = FavoriteService();
  
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal() {
    _shopService.setSupabaseMode(true);
  }
  
  // Cache
  DashboardData? _cachedData;
  DateTime? _lastFetchTime;
  static const _cacheValidDuration = Duration(minutes: 5);
  
  bool get _isCacheValid {
    if (_cachedData == null || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }
  
  void clearCache() {
    _cachedData = null;
    _lastFetchTime = null;
    _eventService.clearCache();
  }
  
  // Progressive loading - returns a stream that emits data as it becomes available
  Stream<DashboardData> getDashboardDataProgressive({bool forceRefresh = false}) async* {
    // Return cached data immediately if available and valid
    if (!forceRefresh && _isCacheValid && _cachedData != null) {
      yield _cachedData!;
      return;
    }
    
    // Track loading status for each section
    final sectionStatus = <String, bool>{
      'stats': false,
      'events': false,
      'announcements': false,
      'newShops': false,
      'popularShops': false,
      'favoriteShops': false,
    };
    
    // Initialize with empty data
    DashboardData currentData = DashboardData(
      featuredEvents: [],
      newShops: [],
      popularShops: [],
      recentAnnouncements: [],
      favoriteShops: [],
      stats: DashboardStats(
        totalShops: 0,
        activeEvents: 0,
        weeklyReviews: 0,
        totalAnnouncements: 0,
      ),
      isLoadingComplete: false,
      sectionLoadingStatus: Map.from(sectionStatus),
    );
    
    // Emit initial empty state
    yield currentData;
    
    try {
      // Priority 1: Quick Stats (fastest to load)
      final statsFuture = _fetchStats();
      final stats = await statsFuture;
      sectionStatus['stats'] = true;
      currentData = DashboardData(
        featuredEvents: currentData.featuredEvents,
        newShops: currentData.newShops,
        popularShops: currentData.popularShops,
        recentAnnouncements: currentData.recentAnnouncements,
        favoriteShops: currentData.favoriteShops,
        stats: stats,
        isLoadingComplete: false,
        sectionLoadingStatus: Map.from(sectionStatus),
      );
      yield currentData;
      
      // Priority 2: Recent Announcements (text-based, fast)
      final announcementsFuture = _fetchRecentAnnouncements();
      final announcements = await announcementsFuture;
      sectionStatus['announcements'] = true;
      currentData = DashboardData(
        featuredEvents: currentData.featuredEvents,
        newShops: currentData.newShops,
        popularShops: currentData.popularShops,
        recentAnnouncements: announcements,
        favoriteShops: currentData.favoriteShops,
        stats: currentData.stats,
        isLoadingComplete: false,
        sectionLoadingStatus: Map.from(sectionStatus),
      );
      yield currentData;
      
      // Priority 3: Featured Events (important for engagement)
      final eventsFuture = _fetchFeaturedEvents();
      final events = await eventsFuture;
      sectionStatus['events'] = true;
      currentData = DashboardData(
        featuredEvents: events,
        newShops: currentData.newShops,
        popularShops: currentData.popularShops,
        recentAnnouncements: currentData.recentAnnouncements,
        favoriteShops: currentData.favoriteShops,
        stats: currentData.stats,
        isLoadingComplete: false,
        sectionLoadingStatus: Map.from(sectionStatus),
      );
      yield currentData;
      
      // Priority 4 & 5: Load remaining data in parallel
      final remainingData = await Future.wait([
        _fetchNewShops(),
        _fetchPopularShops(),
        _fetchFavoriteShops(),
      ]);
      
      sectionStatus['newShops'] = true;
      sectionStatus['popularShops'] = true;
      sectionStatus['favoriteShops'] = true;
      
      currentData = DashboardData(
        featuredEvents: currentData.featuredEvents,
        newShops: remainingData[0],
        popularShops: remainingData[1],
        recentAnnouncements: currentData.recentAnnouncements,
        favoriteShops: remainingData[2],
        stats: currentData.stats,
        isLoadingComplete: true,  // All sections loaded
        sectionLoadingStatus: Map.from(sectionStatus),
      );
      
      // Cache the complete data
      _cachedData = currentData;
      _lastFetchTime = DateTime.now();
      
      yield currentData;
      
    } catch (e) {
      AppLogger.e('Error in progressive dashboard loading', e);
      
      // If we have partial data, yield it
      if (currentData.stats.totalShops > 0 || 
          currentData.featuredEvents.isNotEmpty ||
          currentData.recentAnnouncements.isNotEmpty) {
        yield currentData;
      } else if (_cachedData != null) {
        // Fall back to cached data if available
        yield _cachedData!;
      }
    }
  }
  
  Future<DashboardData> getDashboardData({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cachedData!;
    }
    
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _fetchFeaturedEvents(),
        _fetchNewShops(),
        _fetchPopularShops(),
        _fetchRecentAnnouncements(),
        _fetchFavoriteShops(),
        _fetchStats(),
      ]);
      
      final data = DashboardData(
        featuredEvents: results[0] as List<Event>,
        newShops: results[1] as List<Shop>,
        popularShops: results[2] as List<Shop>,
        recentAnnouncements: results[3] as List<Announcement>,
        favoriteShops: results[4] as List<Shop>,
        stats: results[5] as DashboardStats,
      );
      
      _cachedData = data;
      _lastFetchTime = DateTime.now();
      
      return data;
    } catch (e) {
      AppLogger.e('Error fetching dashboard data', e);
      
      // Return cached data if available, otherwise empty data
      return _cachedData ?? DashboardData(
        featuredEvents: [],
        newShops: [],
        popularShops: [],
        recentAnnouncements: [],
        favoriteShops: [],
        stats: DashboardStats(
          totalShops: 0,
          activeEvents: 0,
          weeklyReviews: 0,
          totalAnnouncements: 0,
        ),
      );
    }
  }
  
  Future<List<Event>> _fetchFeaturedEvents() async {
    try {
      return await _eventService.getFeaturedEvents();
    } catch (e) {
      AppLogger.e('Error fetching featured events', e);
      return [];
    }
  }
  
  Future<List<Shop>> _fetchNewShops() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final shops = await _shopService.getAllShops();
      
      // Filter shops created within the last 30 days
      final newShops = shops.where((shop) {
        return shop.createdAt.isAfter(thirtyDaysAgo);
      }).toList();
      
      // Sort by creation date (newest first)
      newShops.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Return max 10 shops
      return newShops.take(10).toList();
    } catch (e) {
      AppLogger.e('Error fetching new shops', e);
      return [];
    }
  }
  
  Future<List<Shop>> _fetchPopularShops() async {
    try {
      final shops = await _shopService.getAllShops();
      
      // Get ratings for all shops
      final shopIds = shops.map((s) => s.id).toList();
      final ratings = await _reviewService.getMultipleShopRatings(shopIds);
      
      // Create a list of shops with their ratings
      final shopsWithRatings = shops.map((shop) {
        final rating = ratings[shop.id];
        return {
          'shop': shop,
          'rating': rating?.averageRating ?? 0.0,
          'reviewCount': rating?.reviewCount ?? 0,
        };
      }).toList();
      
      // Sort by rating and review count
      shopsWithRatings.sort((a, b) {
        final ratingCompare = (b['rating'] as double).compareTo(a['rating'] as double);
        if (ratingCompare != 0) return ratingCompare;
        return (b['reviewCount'] as int).compareTo(a['reviewCount'] as int);
      });
      
      // Return top 5 shops
      return shopsWithRatings
          .take(5)
          .map((item) => item['shop'] as Shop)
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching popular shops', e);
      return [];
    }
  }
  
  Future<List<Announcement>> _fetchRecentAnnouncements() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      // Get all active announcements
      final allShops = await _shopService.getAllShops();
      final allAnnouncements = <Announcement>[];
      
      for (final shop in allShops) {
        final announcements = await _announcementService.getActiveAnnouncements(shop.id);
        allAnnouncements.addAll(announcements);
      }
      
      // Filter recent and important announcements
      final recentAnnouncements = allAnnouncements.where((announcement) {
        return announcement.isValid && 
               (announcement.isImportant || announcement.createdAt.isAfter(sevenDaysAgo));
      }).toList();
      
      // Sort by importance and creation date
      recentAnnouncements.sort((a, b) {
        if (a.isImportant != b.isImportant) {
          return a.isImportant ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      
      // Return max 10 announcements
      return recentAnnouncements.take(10).toList();
    } catch (e) {
      AppLogger.e('Error fetching recent announcements', e);
      return [];
    }
  }
  
  Future<List<Shop>> _fetchFavoriteShops() async {
    try {
      final favoriteShopIds = await _favoriteService.getUserFavorites();
      if (favoriteShopIds.isEmpty) return [];
      
      final allShops = await _shopService.getAllShops();
      return allShops.where((shop) => favoriteShopIds.contains(shop.id)).toList();
    } catch (e) {
      AppLogger.e('Error fetching favorite shops', e);
      return [];
    }
  }
  
  Future<DashboardStats> _fetchStats() async {
    try {
      // Get total shops count
      final shops = await _shopService.getAllShops();
      final totalShops = shops.length;
      
      // Get active events count
      final eventStats = await _eventService.getEventStats();
      final activeEvents = eventStats['activeCount'] ?? 0;
      
      // Get weekly reviews count
      final weekStart = DateTime.now().subtract(const Duration(days: 7));
      final allReviews = <Review>[];
      
      for (final shop in shops) {
        final reviews = await _reviewService.getShopReviews(shop.id);
        allReviews.addAll(reviews);
      }
      
      final weeklyReviews = allReviews.where((review) {
        return review.createdAt.isAfter(weekStart);
      }).length;
      
      // Get total announcements count
      int totalAnnouncements = 0;
      for (final shop in shops) {
        final announcements = await _announcementService.getActiveAnnouncements(shop.id);
        totalAnnouncements += announcements.length;
      }
      
      return DashboardStats(
        totalShops: totalShops,
        activeEvents: activeEvents,
        weeklyReviews: weeklyReviews,
        totalAnnouncements: totalAnnouncements,
      );
    } catch (e) {
      AppLogger.e('Error fetching dashboard stats', e);
      return DashboardStats(
        totalShops: 0,
        activeEvents: 0,
        weeklyReviews: 0,
        totalAnnouncements: 0,
      );
    }
  }
}