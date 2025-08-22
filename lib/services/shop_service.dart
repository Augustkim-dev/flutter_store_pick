import 'package:flutter/foundation.dart';
import '../models/shop.dart';
import '../data/dummy_shops.dart';
import 'supabase_service.dart';
import '../utils/app_logger.dart';

class ShopService {
  final SupabaseService _supabaseService = SupabaseService();
  
  // 모드 전환 플래그 (true: Supabase, false: 더미 데이터)
  bool _useSupabase = true;
  
  // Supabase 사용 가능 여부 확인
  bool get isSupabaseEnabled => _useSupabase;
  
  // Supabase 모드 설정
  void setSupabaseMode(bool enabled) {
    _useSupabase = enabled;
  }
  
  // 모든 상점 가져오기
  Future<List<Shop>> getAllShops() async {
    if (!_useSupabase) {
      // 더미 데이터 반환
      return DummyShops.shops;
    }
    
    try {
      // Supabase에서 데이터 가져오기
      final response = await _supabaseService.client
          .from('shops')
          .select()
          .order('created_at', ascending: false);
      
      final List<Shop> shops = (response as List)
          .map((json) => Shop.fromJson(json))
          .toList();
      
      return shops;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching shops from Supabase: $e');
      }
      // 에러 발생 시 더미 데이터 반환
      return DummyShops.shops;
    }
  }
  
  // 상점 ID로 조회
  Future<Shop?> getShopById(String id) async {
    AppLogger.d('getShopById called with id: $id, useSupabase: $_useSupabase');
    if (!_useSupabase) {
      // 더미 데이터에서 찾기
      try {
        final shop = DummyShops.shops.firstWhere((shop) => shop.id == id);
        AppLogger.d('Found shop in dummy data: ${shop.name}');
        return shop;
      } catch (e) {
        AppLogger.w('Shop not found in dummy data with id: $id');
        AppLogger.d('Available shop IDs: ${DummyShops.shops.map((s) => s.id).toList()}');
        return null;
      }
    }
    
    try {
      // Supabase에서 단일 상점 조회
      final response = await _supabaseService.client
          .from('shops')
          .select()
          .eq('id', id)
          .single();
      
      return Shop.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching shop by id from Supabase: $e');
      }
      // 에러 발생 시 더미 데이터에서 찾기
      try {
        return DummyShops.shops.firstWhere((shop) => shop.id == id);
      } catch (e) {
        return null;
      }
    }
  }
  
  // 상점 타입별 필터링
  Future<List<Shop>> getShopsByType(ShopType type) async {
    final allShops = await getAllShops();
    
    if (type == ShopType.hybrid) {
      // hybrid는 정확히 hybrid 타입만 반환
      return allShops.where((shop) => shop.shopType == type).toList();
    }
    
    // offline이나 online의 경우 hybrid도 포함
    return allShops.where((shop) {
      if (type == ShopType.offline) {
        return shop.isOffline;
      } else if (type == ShopType.online) {
        return shop.isOnline;
      }
      return false;
    }).toList();
  }
  
  // 간단한 검색 기능 (simple_search 함수 사용)
  Future<List<Shop>> simpleSearchShops(String query) async {
    if (query.isEmpty) {
      return getAllShops();
    }
    
    if (!_useSupabase) {
      // 더미 데이터에서 검색
      final lowercaseQuery = query.toLowerCase();
      return DummyShops.shops.where((shop) {
        return shop.name.toLowerCase().contains(lowercaseQuery) ||
               shop.description.toLowerCase().contains(lowercaseQuery) ||
               shop.brands.any((brand) => 
                   brand.toLowerCase().contains(lowercaseQuery));
      }).toList();
    }
    
    try {
      // simple_search RPC 함수 호출
      final response = await _supabaseService.client
          .rpc('simple_search', params: {'query_text': query});
      
      if (response == null) {
        return [];
      }
      
      final List<Shop> shops = (response as List)
          .map((json) {
            // 함수에서 반환된 컬럼명을 Shop 모델의 필드명으로 매핑
            final shopData = <String, dynamic>{
              'id': json['shop_id'],
              'name': json['shop_name'],
              'shop_type': json['shop_type'],
              'description': json['shop_description'],
              'brands': json['shop_brands'],
              'rating': json['shop_rating'],
              'address': json['shop_address'],
              'website_url': json['shop_website_url'],
            };
            return Shop.fromJson(shopData);
          })
          .toList();
      
      return shops;
    } catch (e) {
      if (kDebugMode) {
        print('Error in simple search: $e');
      }
      return [];
    }
  }
  
  // 검색 기능 (한글/영어 통합 검색 - search_all 함수 사용)
  Future<List<Shop>> searchShops(String query) async {
    if (query.isEmpty) {
      return getAllShops();
    }
    
    final lowercaseQuery = query.toLowerCase();
    
    if (!_useSupabase) {
      // 더미 데이터에서 검색
      return DummyShops.shops.where((shop) {
        return shop.name.toLowerCase().contains(lowercaseQuery) ||
               shop.description.toLowerCase().contains(lowercaseQuery) ||
               shop.brands.any((brand) => 
                   brand.toLowerCase().contains(lowercaseQuery));
      }).toList();
    }
    
    try {
      // RPC 함수를 사용한 통합 검색 (한글/영어 브랜드명 지원)
      final response = await _supabaseService.client
          .rpc('search_all', params: {'query_text': query});
      
      if (response == null) {
        return [];
      }
      
      final List<Shop> shops = (response as List)
          .map((json) {
            // 함수에서 반환된 컬럼명을 Shop 모델의 필드명으로 매핑
            final shopData = <String, dynamic>{
              'id': json['shop_id'],
              'name': json['shop_name'],
              'shop_type': json['shop_type'],
              'description': json['shop_description'],
              'brands': json['shop_brands'],
              'rating': json['shop_rating'],
              'review_count': json['shop_review_count'],
              'image_url': json['shop_image_url'],
              'address': json['shop_address'],
              'phone': json['shop_phone'],
              'latitude': json['shop_latitude'],
              'longitude': json['shop_longitude'],
              'website_url': json['shop_website_url'],
            };
            return Shop.fromJson(shopData);
          })
          .toList();
      
      return shops;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching shops with RPC: $e');
      }
      
      // RPC 실패 시 기존 방식으로 폴백
      try {
        final nameDescResponse = await _supabaseService.client
            .from('shops')
            .select()
            .or('name.ilike.%$query%,description.ilike.%$query%')
            .order('rating', ascending: false);
        
        final List<Shop> shops = (nameDescResponse as List)
            .map((json) => Shop.fromJson(json))
            .toList();
        
        return shops;
      } catch (fallbackError) {
        if (kDebugMode) {
          print('Error in fallback search: $fallbackError');
        }
        // 모든 검색 실패 시 더미 데이터에서 검색
        return DummyShops.shops.where((shop) {
          return shop.name.toLowerCase().contains(lowercaseQuery) ||
                 shop.description.toLowerCase().contains(lowercaseQuery) ||
                 shop.brands.any((brand) => 
                     brand.toLowerCase().contains(lowercaseQuery));
        }).toList();
      }
    }
  }
  
  // 인기 상점 가져오기 (평점 순)
  Future<List<Shop>> getPopularShops({int limit = 5}) async {
    final allShops = await getAllShops();
    allShops.sort((a, b) => b.rating.compareTo(a.rating));
    return allShops.take(limit).toList();
  }
  
  // 최신 상점 가져오기
  Future<List<Shop>> getRecentShops({int limit = 5}) async {
    final allShops = await getAllShops();
    allShops.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allShops.take(limit).toList();
  }
  
  // 소유자별 상점 가져오기
  Future<List<Shop>> getShopsByOwner(String ownerId) async {
    if (!_useSupabase) {
      // 더미 데이터에서는 빈 리스트 반환
      return [];
    }
    
    try {
      final response = await _supabaseService.client
          .from('shops')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);
      
      final List<Shop> shops = (response as List)
          .map((json) => Shop.fromJson(json))
          .toList();
      
      return shops;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching shops by owner: $e');
      }
      return [];
    }
  }
  
  // 상점 정보 업데이트
  Future<bool> updateShop(Shop shop) async {
    if (!_useSupabase) {
      return false;
    }
    
    try {
      await _supabaseService.client
          .from('shops')
          .update(shop.toJson())
          .eq('id', shop.id);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating shop: $e');
      }
      return false;
    }
  }
  
  // 상점 통계 가져오기
  Future<Map<String, dynamic>> getShopStats(String shopId) async {
    if (!_useSupabase) {
      return {
        'review_count': 0,
        'average_rating': 0.0,
        'favorite_count': 0,
      };
    }
    
    try {
      final response = await _supabaseService.client
          .rpc('get_shop_stats', params: {'shop_uuid': shopId});
      
      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }
      return {
        'review_count': 0,
        'average_rating': 0.0,
        'favorite_count': 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching shop stats: $e');
      }
      return {
        'review_count': 0,
        'average_rating': 0.0,
        'favorite_count': 0,
      };
    }
  }
}