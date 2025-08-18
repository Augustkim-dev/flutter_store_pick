import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import '../models/shop.dart';
import '../services/shop_service.dart';
import '../widgets/shop_card.dart';
import 'shop_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ShopService _shopService = ShopService();
  Timer? _debounceTimer;
  
  List<Shop> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _currentQuery = '';
  
  @override
  void initState() {
    super.initState();
    _shopService.setSupabaseMode(true);
    _loadRecentSearches();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }
  
  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query); // 중복 제거
    _recentSearches.insert(0, query); // 최신 검색어를 앞에 추가
    
    // 최대 10개까지만 저장
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }
    
    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }
  
  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      _recentSearches = [];
    });
  }
  
  void _onSearchChanged(String query) {
    _currentQuery = query;
    
    // 디바운싱 적용
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }
  
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    
    try {
      final results = await _shopService.searchShops(query);
      if (_currentQuery == query) { // 현재 쿼리와 일치하는 경우에만 업데이트
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_currentQuery == query) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    }
  }
  
  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      _saveRecentSearch(query.trim());
      _performSearch(query);
    }
  }
  
  void _onRecentSearchTap(String query) {
    _searchController.text = query;
    _onSearchChanged(query);
    _onSearchSubmitted(query);
  }
  
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchController.text.isNotEmpty 
              ? AppColors.primaryPink 
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: false,
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
        decoration: InputDecoration(
          hintText: '상점 또는 브랜드 검색',
          hintStyle: TextStyle(color: AppColors.gray),
          prefixIcon: Icon(Icons.search, color: AppColors.gray),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.gray),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 검색어',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                child: Text(
                  '모두 지우기',
                  style: TextStyle(color: AppColors.gray, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((search) {
              return InkWell(
                onTap: () => _onRecentSearchTap(search),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gray.withAlpha(51),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: AppColors.gray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        search,
                        style: TextStyle(
                          color: AppColors.darkGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (!_hasSearched) {
      return Expanded(
        child: Column(
          children: [
            _buildRecentSearches(),
            const SizedBox(height: 40),
            Icon(
              Icons.search,
              size: 80,
              color: AppColors.secondaryAccent.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              '검색어를 입력해주세요',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.gray,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_searchResults.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: AppColors.gray.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                '\'$_currentQuery\'에 대한 검색 결과가 없습니다',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.gray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '검색 결과 ${_searchResults.length}개',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.gray,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final shop = _searchResults[index];
                return ShopCard(
                  shop: shop,
                  searchQuery: _currentQuery, // 검색어 하이라이트를 위해 전달
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ShopDetailScreen(shop: shop),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
        automaticallyImplyLeading: false,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // 키보드 숨기기
        },
        child: Column(
          children: [
            _buildSearchBar(),
            _buildSearchResults(),
          ],
        ),
      ),
    );
  }
}