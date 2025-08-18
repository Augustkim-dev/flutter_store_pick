import 'package:flutter/foundation.dart';
import '../models/shop.dart';
import '../data/dummy_shops.dart';
import 'supabase_service.dart';

class ShopService {
  final SupabaseService _supabaseService = SupabaseService();
  
  // 모드 전환 플래그 (true: Supabase, false: 더미 데이터)
  bool _useSupabase = false;
  
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
    if (!_useSupabase) {
      // 더미 데이터에서 찾기
      try {
        return DummyShops.shops.firstWhere((shop) => shop.id == id);
      } catch (e) {
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
  
  // 검색 기능
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
      // Supabase에서 검색
      final response = await _supabaseService.client
          .from('shops')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('rating', ascending: false);
      
      final List<Shop> shops = (response as List)
          .map((json) => Shop.fromJson(json))
          .toList();
      
      return shops;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching shops in Supabase: $e');
      }
      // 에러 발생 시 더미 데이터에서 검색
      return DummyShops.shops.where((shop) {
        return shop.name.toLowerCase().contains(lowercaseQuery) ||
               shop.description.toLowerCase().contains(lowercaseQuery) ||
               shop.brands.any((brand) => 
                   brand.toLowerCase().contains(lowercaseQuery));
      }).toList();
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
}