import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/dummy_shops.dart';
import '../models/shop.dart';
import '../widgets/shop_card.dart';
import 'shop_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ShopType? selectedFilter;
  List<Shop> filteredShops = DummyShops.shops;

  void _filterShops(ShopType? type) {
    setState(() {
      selectedFilter = type;
      if (type == null) {
        filteredShops = DummyShops.shops;
      } else {
        filteredShops = DummyShops.shops
            .where((shop) => shop.shopType == type)
            .toList();
      }
    });
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
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('온/오프라인'),
                  selected: selectedFilter == ShopType.hybrid,
                  onSelected: (_) => _filterShops(ShopType.hybrid),
                  selectedColor: AppColors.secondaryPurple,
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
              ListTile(
                leading: const Icon(Icons.storefront),
                title: const Text('온/오프라인 통합'),
                onTap: () {
                  _filterShops(ShopType.hybrid);
                  Navigator.pop(context);
                },
                selected: selectedFilter == ShopType.hybrid,
              ),
            ],
          ),
        );
      },
    );
  }
}