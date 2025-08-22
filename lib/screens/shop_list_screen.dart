import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/shop.dart';
import '../widgets/shop_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_widget_custom.dart';
import '../services/shop_service.dart';
import '../services/review_service.dart';
import '../models/review.dart';
import 'shop_detail_screen_v2.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({super.key});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final ShopService _shopService = ShopService();
  final ReviewService _reviewService = ReviewService();
  ShopType? selectedFilter;
  List<Shop> filteredShops = [];
  List<Shop> _allShops = [];
  Map<String, ShopRating> shopRatings = {};
  bool isLoading = true;
  String? errorMessage;
  
  // 추가 필터 옵션
  Set<String> selectedBrands = {};
  Set<String> selectedCategories = {};
  Set<String> selectedFacilities = {};
  bool onlyVerified = false;

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
      final shops = await _shopService.getAllShops();
      
      // 상점 목록을 가져온 후 평점 정보도 가져오기
      if (shops.isNotEmpty) {
        final shopIds = shops.map((s) => s.id).toList();
        final ratings = await _reviewService.getMultipleShopRatings(shopIds);
        setState(() {
          shopRatings = ratings;
        });
      }
      
      setState(() {
        _allShops = shops;
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = '상점 정보를 불러오는데 실패했습니다.';
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = List<Shop>.from(_allShops);
    
    // 상점 유형 필터
    if (selectedFilter != null) {
      filtered = filtered.where((shop) => shop.shopType == selectedFilter).toList();
    }
    
    // 브랜드 필터
    if (selectedBrands.isNotEmpty) {
      filtered = filtered.where((shop) => 
        shop.mainBrands.any((brand) => selectedBrands.contains(brand))
      ).toList();
    }
    
    // 카테고리 필터
    if (selectedCategories.isNotEmpty) {
      filtered = filtered.where((shop) => 
        shop.categories.any((cat) => selectedCategories.contains(cat))
      ).toList();
    }
    
    // 편의시설 필터
    if (selectedFacilities.isNotEmpty) {
      filtered = filtered.where((shop) {
        for (var facility in selectedFacilities) {
          switch (facility) {
            case '주차가능':
              if (shop.parkingAvailable != true) return false;
              break;
            case '시착가능':
              if (shop.fittingAvailable != true) return false;
              break;
            case '당일배송':
              if (shop.sameDayDelivery != true) return false;
              break;
            case '픽업서비스':
              if (shop.pickupService != true) return false;
              break;
          }
        }
        return true;
      }).toList();
    }
    
    // 인증 상점 필터
    if (onlyVerified) {
      filtered = filtered.where((shop) => shop.isVerified).toList();
    }
    
    setState(() {
      filteredShops = filtered;
    });
  }

  void _filterShops(ShopType? type) {
    setState(() {
      selectedFilter = type;
      _applyFilters();
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
                ? ListView.builder(
                    itemCount: 5, // 스켈레톤 개수
                    itemBuilder: (context, index) {
                      return const ShopCardSkeleton();
                    },
                  )
                : errorMessage != null
                    ? CustomErrorWidget(
                        message: errorMessage,
                        errorType: ErrorType.network,
                        onRetry: _loadShops,
                      )
                    : filteredShops.isEmpty
                        ? EmptyStateWidget(
                            title: '상점이 없습니다',
                            message: _allShops.isEmpty 
                                ? '등록된 상점이 없습니다'
                                : '필터 조건에 맞는 상점이 없습니다',
                            icon: Icons.store_outlined,
                            action: _allShops.isNotEmpty
                                ? ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedFilter = null;
                                        selectedBrands.clear();
                                        selectedCategories.clear();
                                        selectedFacilities.clear();
                                        onlyVerified = false;
                                        _applyFilters();
                                      });
                                    },
                                    child: const Text('필터 초기화'),
                                  )
                                : null,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadShops,
                            child: ListView.builder(
                              itemCount: filteredShops.length,
                              itemBuilder: (context, index) {
                                final shop = filteredShops[index];
                                final rating = shopRatings[shop.id];
                                return ShopCard(
                                  key: ValueKey(shop.id),
                                  shop: shop,
                                  shopRating: rating,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ShopDetailScreenV2(shopId: shop.id),
                                      ),
                                    );
                                    // 상세 화면에서 돌아온 후 평점 다시 로드
                                    _loadShops();
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '고급 필터',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedFilter = null;
                                selectedBrands.clear();
                                selectedCategories.clear();
                                selectedFacilities.clear();
                                onlyVerified = false;
                                _applyFilters();
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('초기화'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // 상점 유형
                            const Text('상점 유형', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('전체'),
                                  selected: selectedFilter == null,
                                  onSelected: (_) {
                                    setModalState(() {
                                      selectedFilter = null;
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('오프라인'),
                                  selected: selectedFilter == ShopType.offline,
                                  onSelected: (_) {
                                    setModalState(() {
                                      selectedFilter = ShopType.offline;
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('온라인'),
                                  selected: selectedFilter == ShopType.online,
                                  onSelected: (_) {
                                    setModalState(() {
                                      selectedFilter = ShopType.online;
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('온/오프라인'),
                                  selected: selectedFilter == ShopType.hybrid,
                                  onSelected: (_) {
                                    setModalState(() {
                                      selectedFilter = ShopType.hybrid;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // 편의시설
                            const Text('편의시설/서비스', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                FilterChip(
                                  label: const Text('주차가능'),
                                  selected: selectedFacilities.contains('주차가능'),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        selectedFacilities.add('주차가능');
                                      } else {
                                        selectedFacilities.remove('주차가능');
                                      }
                                    });
                                  },
                                ),
                                FilterChip(
                                  label: const Text('시착가능'),
                                  selected: selectedFacilities.contains('시착가능'),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        selectedFacilities.add('시착가능');
                                      } else {
                                        selectedFacilities.remove('시착가능');
                                      }
                                    });
                                  },
                                ),
                                FilterChip(
                                  label: const Text('당일배송'),
                                  selected: selectedFacilities.contains('당일배송'),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        selectedFacilities.add('당일배송');
                                      } else {
                                        selectedFacilities.remove('당일배송');
                                      }
                                    });
                                  },
                                ),
                                FilterChip(
                                  label: const Text('픽업서비스'),
                                  selected: selectedFacilities.contains('픽업서비스'),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        selectedFacilities.add('픽업서비스');
                                      } else {
                                        selectedFacilities.remove('픽업서비스');
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // 기타 옵션
                            const Text('기타 옵션', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              title: const Text('인증된 상점만'),
                              value: onlyVerified,
                              onChanged: (value) {
                                setModalState(() {
                                  onlyVerified = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _applyFilters();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('필터 적용 (${filteredShops.length}개 상점)'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}