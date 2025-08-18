import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestFavoriteScreen extends StatefulWidget {
  const TestFavoriteScreen({super.key});

  @override
  State<TestFavoriteScreen> createState() => _TestFavoriteScreenState();
}

class _TestFavoriteScreenState extends State<TestFavoriteScreen> {
  final _supabase = Supabase.instance.client;
  String _output = '';
  
  @override
  void initState() {
    super.initState();
    _runTests();
  }
  
  void _log(String message) {
    setState(() {
      _output += '$message\n';
    });
    print(message);
  }
  
  Future<void> _runTests() async {
    _log('=== Starting Favorite Tests ===\n');
    
    // Test 1: Check auth
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _log('❌ Not logged in - Please login first');
      return;
    }
    _log('✅ Logged in as: ${user.email}');
    _log('   User ID: ${user.id}\n');
    
    // Test 2: Check profile
    _log('Testing profiles table...');
    try {
      // 먼저 upsert로 프로필 확실하게 생성
      _log('   Using upsert to ensure profile exists...');
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'user_type': 'general',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      
      // 프로필 확인
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (profile != null) {
        _log('✅ Profile exists');
        _log('   Data: $profile');
      } else {
        _log('❌ Profile not found even after upsert');
      }
    } catch (e) {
      _log('❌ Profile error: $e');
    }
    _log('');
    
    // Test 3: Get first shop
    _log('Getting test shop...');
    String? testShopId;
    try {
      final shops = await _supabase
          .from('shops')
          .select()
          .limit(1);
      
      if (shops.isNotEmpty) {
        testShopId = shops[0]['id'];
        _log('✅ Test shop: ${shops[0]['name']} (ID: $testShopId)');
      } else {
        _log('❌ No shops found');
        return;
      }
    } catch (e) {
      _log('❌ Error getting shops: $e');
      return;
    }
    _log('');
    
    // Test 4: Check current favorites
    _log('Checking current favorites...');
    try {
      final favorites = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', user.id);
      
      _log('✅ Current favorites count: ${favorites.length}');
      for (var fav in favorites) {
        _log('   - Shop ID: ${fav['shop_id']}');
      }
    } catch (e) {
      _log('❌ Error reading favorites: $e');
    }
    _log('');
    
    // Test 5: Add favorite
    _log('Testing add favorite...');
    try {
      // First remove if exists
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('shop_id', testShopId!);
      
      // Then add
      await _supabase.from('favorites').insert({
        'user_id': user.id,
        'shop_id': testShopId,
      });
      _log('✅ Favorite added successfully');
    } catch (e) {
      _log('❌ Error adding favorite: $e');
    }
    _log('');
    
    // Test 6: Check if favorite exists
    _log('Checking if favorite exists...');
    try {
      final check = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('shop_id', testShopId!)
          .maybeSingle();
      
      if (check != null) {
        _log('✅ Favorite exists in database');
      } else {
        _log('❌ Favorite not found in database');
      }
    } catch (e) {
      _log('❌ Error checking favorite: $e');
    }
    _log('');
    
    // Test 7: Remove favorite
    _log('Testing remove favorite...');
    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('shop_id', testShopId!);
      _log('✅ Favorite removed successfully');
    } catch (e) {
      _log('❌ Error removing favorite: $e');
    }
    _log('');
    
    // Test 8: Get favorite shops with details
    _log('Testing get favorite shops with details...');
    try {
      // First add a favorite
      await _supabase.from('favorites').insert({
        'user_id': user.id,
        'shop_id': testShopId!,
      });
      
      // Then query with join
      final result = await _supabase
          .from('favorites')
          .select('*, shops(*)')
          .eq('user_id', user.id);
      
      _log('✅ Got ${result.length} favorite(s) with details');
      for (var item in result) {
        final shop = item['shops'];
        if (shop != null) {
          _log('   - ${shop['name']} (${shop['shop_type']})');
        }
      }
    } catch (e) {
      _log('❌ Error getting favorite shops: $e');
    }
    
    _log('\n=== Tests Complete ===');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Favorites'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              _output,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _output = '';
                });
                _runTests();
              },
              child: const Text('Run Tests Again'),
            ),
          ],
        ),
      ),
    );
  }
}