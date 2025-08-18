import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _authService = AuthService();
  final _favoriteService = FavoriteService();
  final _supabase = Supabase.instance.client;
  
  String _debugInfo = '';
  
  @override
  void initState() {
    super.initState();
    _runDebugChecks();
  }
  
  Future<void> _runDebugChecks() async {
    setState(() {
      _debugInfo = 'Running debug checks...\n\n';
    });
    
    // 1. Check auth status
    final user = _authService.currentUser;
    _addDebugInfo('1. Auth Status:');
    if (user != null) {
      _addDebugInfo('  - User ID: ${user.id}');
      _addDebugInfo('  - Email: ${user.email}');
    } else {
      _addDebugInfo('  - Not logged in');
    }
    
    // 2. Check Supabase connection
    _addDebugInfo('\n2. Supabase Connection:');
    try {
      final response = await _supabase.from('shops').select().limit(1);
      _addDebugInfo('  - Connected successfully');
      _addDebugInfo('  - Shops table accessible: ${response.isNotEmpty}');
    } catch (e) {
      _addDebugInfo('  - Connection error: $e');
    }
    
    // 3. Check favorites table
    _addDebugInfo('\n3. Favorites Table:');
    if (user != null) {
      try {
        // Try to get favorites
        final favorites = await _supabase
            .from('favorites')
            .select()
            .eq('user_id', user.id);
        _addDebugInfo('  - Can read favorites: Yes');
        _addDebugInfo('  - Current favorites count: ${favorites.length}');
        
        // Try to get shops
        final shops = await _supabase.from('shops').select();
        if (shops.isNotEmpty) {
          final testShopId = shops[0]['id'];
          _addDebugInfo('  - Test shop ID: $testShopId');
          
          // Test add favorite
          try {
            await _supabase.from('favorites').insert({
              'user_id': user.id,
              'shop_id': testShopId,
            });
            _addDebugInfo('  - Can add favorite: Yes');
            
            // Test remove favorite
            await _supabase
                .from('favorites')
                .delete()
                .eq('user_id', user.id)
                .eq('shop_id', testShopId);
            _addDebugInfo('  - Can remove favorite: Yes');
          } catch (e) {
            _addDebugInfo('  - Write error: $e');
          }
        }
      } catch (e) {
        _addDebugInfo('  - Read error: $e');
      }
    } else {
      _addDebugInfo('  - Cannot test (not logged in)');
    }
    
    // 4. Check profiles table
    _addDebugInfo('\n4. Profiles Table:');
    if (user != null) {
      try {
        final profile = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null) {
          _addDebugInfo('  - Profile exists: Yes');
          _addDebugInfo('  - User type: ${profile['user_type'] ?? 'null'}');
        } else {
          _addDebugInfo('  - Profile exists: No');
          // Try to create profile
          try {
            await _supabase.from('profiles').insert({
              'id': user.id,
              'user_type': 'general',
            });
            _addDebugInfo('  - Profile created successfully');
          } catch (e) {
            _addDebugInfo('  - Profile creation error: $e');
          }
        }
      } catch (e) {
        _addDebugInfo('  - Profile error: $e');
      }
    }
    
    // 5. Test favorite service
    _addDebugInfo('\n5. Favorite Service Test:');
    if (user != null) {
      try {
        final shops = await _supabase.from('shops').select().limit(1);
        if (shops.isNotEmpty) {
          final testShopId = shops[0]['id'];
          
          // Check favorite
          final isFavorite = await _favoriteService.checkFavorite(testShopId);
          _addDebugInfo('  - Check favorite: $isFavorite');
          
          // Toggle favorite
          final toggleResult = await _favoriteService.toggleFavorite(testShopId);
          _addDebugInfo('  - Toggle result: $toggleResult');
          
          // Check again
          final isFavoriteAfter = await _favoriteService.checkFavorite(testShopId);
          _addDebugInfo('  - After toggle: $isFavoriteAfter');
        }
      } catch (e) {
        _addDebugInfo('  - Service error: $e');
      }
    }
  }
  
  void _addDebugInfo(String info) {
    setState(() {
      _debugInfo += '$info\n';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _debugInfo,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _runDebugChecks,
              child: const Text('Run Debug Checks Again'),
            ),
          ],
        ),
      ),
    );
  }
}