import 'package:flutter/foundation.dart';
import '../models/brand.dart';
import 'supabase_service.dart';

class BrandService {
  final SupabaseService _supabaseService = SupabaseService();
  
  // 브랜드 검색 (한글/영어 통합)
  Future<List<Brand>> searchBrands(String query) async {
    if (query.isEmpty) {
      return [];
    }
    
    try {
      final response = await _supabaseService.client
          .rpc('search_brands', params: {'search_query': query});
      
      if (response == null) {
        return [];
      }
      
      final List<Brand> brands = (response as List)
          .map((json) {
            // 함수에서 반환된 컬럼명을 Brand 모델의 필드명으로 매핑
            final brandData = <String, dynamic>{
              'id': json['brand_id'],
              'name': json['brand_name'],
              'name_ko': json['brand_name_ko'],
              'logo_url': json['brand_logo_url'],
            };
            return Brand.fromJson(brandData);
          })
          .toList();
      
      return brands;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching brands: $e');
      }
      return [];
    }
  }
  
  // 브랜드 자동완성 제안
  Future<List<Map<String, dynamic>>> suggestBrands(String query, {int limit = 10}) async {
    if (query.isEmpty) {
      return [];
    }
    
    try {
      final response = await _supabaseService.client
          .rpc('suggest_brands', params: {
            'search_query': query,
            'limit_count': limit
          });
      
      if (response == null) {
        return [];
      }
      
      // 함수에서 반환된 컬럼명을 매핑하여 반환
      return (response as List).map((item) => {
        'id': item['brand_id'],
        'name': item['brand_name'],
        'name_ko': item['brand_name_ko'],
        'display_name': item['display_name'],
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error suggesting brands: $e');
      }
      return [];
    }
  }
  
  // 모든 브랜드 가져오기
  Future<List<Brand>> getAllBrands() async {
    try {
      final response = await _supabaseService.client
          .from('brands')
          .select()
          .order('name');
      
      if (response == null) {
        return [];
      }
      
      final List<Brand> brands = (response as List)
          .map((json) => Brand.fromJson(json))
          .toList();
      
      return brands;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching all brands: $e');
      }
      return [];
    }
  }
  
  // 브랜드 ID로 조회
  Future<Brand?> getBrandById(String id) async {
    try {
      final response = await _supabaseService.client
          .from('brands')
          .select()
          .eq('id', id)
          .single();
      
      return Brand.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching brand by id: $e');
      }
      return null;
    }
  }
}