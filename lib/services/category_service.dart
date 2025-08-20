import 'package:flutter/foundation.dart';
import '../models/shop_category.dart';
import 'supabase_service.dart';

class CategoryService {
  final SupabaseService _supabaseService = SupabaseService();
  
  // 상점의 카테고리 목록 가져오기
  Future<List<ShopCategory>> getShopCategories(String shopId) async {
    try {
      final response = await _supabaseService.client
          .from('shop_categories')
          .select()
          .eq('shop_id', shopId)
          .order('category_name');
      
      if (response == null) {
        return [];
      }
      
      final List<ShopCategory> categories = (response as List)
          .map((json) => ShopCategory.fromJson(json))
          .toList();
      
      return categories;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching shop categories: $e');
      }
      return [];
    }
  }
  
  // 카테고리 추가
  Future<bool> addCategory(ShopCategory category) async {
    try {
      await _supabaseService.client
          .from('shop_categories')
          .insert(category.toJson());
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding category: $e');
      }
      return false;
    }
  }
  
  // 여러 카테고리 한번에 추가
  Future<bool> addMultipleCategories(List<ShopCategory> categories) async {
    try {
      if (categories.isEmpty) return true;
      
      final data = categories.map((c) => c.toJson()).toList();
      
      await _supabaseService.client
          .from('shop_categories')
          .insert(data);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding multiple categories: $e');
      }
      return false;
    }
  }
  
  // 카테고리 업데이트
  Future<bool> updateCategory(ShopCategory category) async {
    try {
      await _supabaseService.client
          .from('shop_categories')
          .update({
            'category_name': category.categoryName,
            'is_specialized': category.isSpecialized,
          })
          .eq('id', category.id);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating category: $e');
      }
      return false;
    }
  }
  
  // 카테고리 삭제
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _supabaseService.client
          .from('shop_categories')
          .delete()
          .eq('id', categoryId);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting category: $e');
      }
      return false;
    }
  }
  
  // 상점의 모든 카테고리 삭제 (재설정용)
  Future<bool> deleteAllShopCategories(String shopId) async {
    try {
      await _supabaseService.client
          .from('shop_categories')
          .delete()
          .eq('shop_id', shopId);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all shop categories: $e');
      }
      return false;
    }
  }
  
  // 카테고리별 상점 검색
  Future<List<String>> getShopsByCategory(String categoryName) async {
    try {
      final response = await _supabaseService.client
          .from('shop_categories')
          .select('shop_id')
          .eq('category_name', categoryName);
      
      if (response == null) {
        return [];
      }
      
      return (response as List)
          .map((item) => item['shop_id'] as String)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching shops by category: $e');
      }
      return [];
    }
  }
  
  // 전문 카테고리 상점 검색
  Future<List<String>> getSpecializedShops(String categoryName) async {
    try {
      final response = await _supabaseService.client
          .from('shop_categories')
          .select('shop_id')
          .eq('category_name', categoryName)
          .eq('is_specialized', true);
      
      if (response == null) {
        return [];
      }
      
      return (response as List)
          .map((item) => item['shop_id'] as String)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching specialized shops: $e');
      }
      return [];
    }
  }
}