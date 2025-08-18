import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/shop.dart';
import '../widgets/shop_card.dart';
import '../services/shop_service.dart';
import 'shop_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShopService _shopService = ShopService();
  ShopType? selectedFilter;
  List<Shop> filteredShops = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _shopService.setSupabaseMode(true); // Supabase 모드 활성화
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final shops = selectedFilter == null
          ? await _shopService.getAllShops()
          : await _shopService.getShopsByType(selectedFilter!);
      
      setState(() {
        filteredShops = shops;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = '상점 정보를 불러오는데 실패했습니다.';
        isLoading = false;
      });
    }
  }

  void _filterShops(ShopType? type) {
    setState(() {
      selectedFilter = type;
    });
    _loadShops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('발레 용품점 찾기'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 칩들
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('전체'),
                  selected: selectedFilter == null,
                  onSelected: (_) => _filterShops(null),
                  selectedColor: AppColors.primaryPink,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('오프라인'),
                  selected: selectedFilter == ShopType.offline,
                  onSelected: (_) => _filterShops(ShopType.offline),
                  selectedColor: AppColors.offlineShop.withAlpha(102),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('온라인'),
                  selected: selectedFilter == ShopType.online,
                  onSelected: (_) => _filterShops(ShopType.online),
                  selectedColor: AppColors.onlineShop.withAlpha(102),
                ),
              ],
            ),
          ),
          
          // 상점 개수
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              '총 ${filteredShops.length}개 상점',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          
          // 상점 리스트
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              errorMessage!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadShops,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                    : filteredShops.isEmpty
                        ? const Center(
                            child: Text('표시할 상점이 없습니다.'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadShops,
                            child: ListView.builder(
                              itemCount: filteredShops.length,
                              itemBuilder: (context, index) {
                                final shop = filteredShops[index];
                                return ShopCard(
                                  shop: shop,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ShopDetailScreen(shop: shop),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
  
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '상점 필터',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('전체 보기'),
                onTap: () {
                  _filterShops(null);
                  Navigator.pop(context);
                },
                selected: selectedFilter == null,
              ),
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text('오프라인 매장'),
                onTap: () {
                  _filterShops(ShopType.offline);
                  Navigator.pop(context);
                },
                selected: selectedFilter == ShopType.offline,
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('온라인 쇼핑몰'),
                onTap: () {
                  _filterShops(ShopType.online);
                  Navigator.pop(context);
                },
                selected: selectedFilter == ShopType.online,
              ),
            ],
          ),
        );
      },
    );
  }
}