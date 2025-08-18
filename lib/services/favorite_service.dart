import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // 프로필 확인 및 생성
  Future<bool> _ensureProfileExists() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    
    try {
      print('Checking profile for favorites - User: ${user.id}');
      
      // upsert를 사용하여 확실하게 프로필 생성
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'user_type': 'general',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      
      // 프로필 존재 확인
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      
      if (profile != null) {
        print('Profile confirmed for favorites');
        return true;
      } else {
        print('Profile still not found after upsert');
        return false;
      }
    } catch (e) {
      print('Error ensuring profile for favorites: $e');
      return false;
    }
  }
  
  // 즐겨찾기 추가
  Future<bool> addFavorite(String shopId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');
    
    print('Adding favorite - User: ${user.id}, Shop: $shopId');
    
    // 프로필 확인 및 생성
    final profileExists = await _ensureProfileExists();
    if (!profileExists) {
      print('Cannot add favorite - profile creation failed');
      return false;
    }
    
    try {
      await _supabase.from('favorites').insert({
        'user_id': user.id,
        'shop_id': shopId,
      });
      print('Favorite added successfully');
      return true;
    } catch (e) {
      print('Error adding favorite: $e');
      // 프로필 문제일 수 있으므로 다시 시도
      if (e.toString().contains('foreign key')) {
        print('Foreign key error - trying to create profile again');
        await _ensureProfileExists();
      }
      return false;
    }
  }
  
  // 즐겨찾기 제거
  Future<bool> removeFavorite(String shopId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');
    
    print('Removing favorite - User: ${user.id}, Shop: $shopId');
    
    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('shop_id', shopId);
      print('Favorite removed successfully');
      return true;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }
  
  // 즐겨찾기 토글
  Future<bool> toggleFavorite(String shopId) async {
    final isFavorite = await checkFavorite(shopId);
    if (isFavorite) {
      return await removeFavorite(shopId);
    } else {
      return await addFavorite(shopId);
    }
  }
  
  // 즐겨찾기 확인
  Future<bool> checkFavorite(String shopId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('No user logged in for checking favorite');
      return false;
    }
    
    print('Checking favorite - User: ${user.id}, Shop: $shopId');
    
    try {
      final response = await _supabase
          .from('favorites')
          .select('shop_id')
          .eq('user_id', user.id)
          .eq('shop_id', shopId)
          .maybeSingle();
      
      final isFavorite = response != null;
      print('Favorite check result: $isFavorite');
      return isFavorite;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }
  
  // 사용자의 즐겨찾기 목록 조회
  Future<List<String>> getUserFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    
    try {
      final response = await _supabase
          .from('favorites')
          .select('shop_id')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => item['shop_id'] as String)
          .toList();
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }
  
  // 즐겨찾기한 상점 목록 조회 (상점 정보 포함)
  Future<List<Map<String, dynamic>>> getFavoriteShops() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    
    try {
      final response = await _supabase
          .from('favorites')
          .select('*, shops(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => item['shops'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching favorite shops: $e');
      return [];
    }
  }
  
  // 즐겨찾기 개수 조회
  Future<int> getFavoriteCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;
    
    try {
      final response = await _supabase
          .from('favorites')
          .select('shop_id')
          .eq('user_id', user.id);
      
      return (response as List).length;
    } catch (e) {
      print('Error counting favorites: $e');
      return 0;
    }
  }
  
  // 실시간 즐겨찾기 변경 스트림
  Stream<List<Map<String, dynamic>>> favoritesStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    
    return _supabase
        .from('favorites')
        .stream(primaryKey: ['user_id', 'shop_id'])
        .eq('user_id', user.id)
        .order('created_at');
  }
}