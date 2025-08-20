import 'package:flutter/foundation.dart';
import '../models/shipping_region.dart';
import 'supabase_service.dart';

class ShippingService {
  final SupabaseService _supabaseService = SupabaseService();
  
  // 상점의 배송 지역 목록 가져오기
  Future<List<ShippingRegion>> getShopShippingRegions(String shopId) async {
    try {
      final response = await _supabaseService.client
          .from('shipping_regions')
          .select()
          .eq('shop_id', shopId)
          .order('region_name');
      
      if (response == null) {
        return [];
      }
      
      final List<ShippingRegion> regions = (response as List)
          .map((json) => ShippingRegion.fromJson(json))
          .toList();
      
      return regions;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching shipping regions: $e');
      }
      return [];
    }
  }
  
  // 배송 지역 추가
  Future<bool> addShippingRegion(ShippingRegion region) async {
    try {
      await _supabaseService.client
          .from('shipping_regions')
          .insert(region.toJson());
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding shipping region: $e');
      }
      return false;
    }
  }
  
  // 여러 배송 지역 한번에 추가
  Future<bool> addMultipleShippingRegions(List<ShippingRegion> regions) async {
    try {
      if (regions.isEmpty) return true;
      
      final data = regions.map((r) => r.toJson()).toList();
      
      await _supabaseService.client
          .from('shipping_regions')
          .insert(data);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding multiple shipping regions: $e');
      }
      return false;
    }
  }
  
  // 배송 지역 업데이트
  Future<bool> updateShippingRegion(ShippingRegion region) async {
    try {
      await _supabaseService.client
          .from('shipping_regions')
          .update({
            'region_name': region.regionName,
            'shipping_fee': region.shippingFee,
            'estimated_days': region.estimatedDays,
          })
          .eq('id', region.id);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating shipping region: $e');
      }
      return false;
    }
  }
  
  // 배송 지역 삭제
  Future<bool> deleteShippingRegion(String regionId) async {
    try {
      await _supabaseService.client
          .from('shipping_regions')
          .delete()
          .eq('id', regionId);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting shipping region: $e');
      }
      return false;
    }
  }
  
  // 상점의 모든 배송 지역 삭제 (재설정용)
  Future<bool> deleteAllShopShippingRegions(String shopId) async {
    try {
      await _supabaseService.client
          .from('shipping_regions')
          .delete()
          .eq('shop_id', shopId);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all shipping regions: $e');
      }
      return false;
    }
  }
  
  // 기본 배송비 설정 (모든 지역 동일)
  Future<bool> setDefaultShippingFee(String shopId, int shippingFee, {int estimatedDays = 2}) async {
    try {
      // 기존 배송 지역 삭제
      await deleteAllShopShippingRegions(shopId);
      
      // 모든 지역에 대해 동일한 배송비 설정
      final regions = ShippingRegion.defaultRegions.map((regionName) => 
        ShippingRegion(
          id: '${shopId}_$regionName',
          shopId: shopId,
          regionName: regionName,
          shippingFee: shippingFee,
          estimatedDays: regionName == '제주' ? estimatedDays + 1 : estimatedDays, // 제주도는 +1일
        )
      ).toList();
      
      return await addMultipleShippingRegions(regions);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting default shipping fee: $e');
      }
      return false;
    }
  }
  
  // 특정 지역 배송비 조회
  Future<ShippingRegion?> getRegionShippingInfo(String shopId, String regionName) async {
    try {
      final response = await _supabaseService.client
          .from('shipping_regions')
          .select()
          .eq('shop_id', shopId)
          .eq('region_name', regionName)
          .single();
      
      return ShippingRegion.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching region shipping info: $e');
      }
      return null;
    }
  }
  
  // 배송비 계산 (지역별)
  Future<int> calculateShippingFee(String shopId, String regionName, {int orderAmount = 0}) async {
    try {
      // 먼저 상점의 무료배송 조건 확인
      final shopResponse = await _supabaseService.client
          .from('shops')
          .select('free_shipping_min')
          .eq('id', shopId)
          .single();
      
      final freeShippingMin = shopResponse['free_shipping_min'] as int?;
      
      // 무료배송 조건 충족시
      if (freeShippingMin != null && orderAmount >= freeShippingMin) {
        return 0;
      }
      
      // 지역별 배송비 조회
      final region = await getRegionShippingInfo(shopId, regionName);
      return region?.shippingFee ?? 3000; // 기본 배송비 3000원
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating shipping fee: $e');
      }
      return 3000; // 에러시 기본 배송비
    }
  }
}