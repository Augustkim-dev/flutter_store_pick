import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/shop.dart';
import '../models/review.dart';
import '../services/shop_service.dart';
import '../services/review_service.dart';
import '../services/announcement_service.dart';
import '../theme/app_colors.dart';
import '../widgets/favorite_button.dart';
import '../widgets/review_list_widget.dart';
import '../widgets/announcement_list_widget.dart';
import '../widgets/business_status_badge.dart';
import '../widgets/shop_info_section.dart';
import '../widgets/image_gallery_viewer.dart';
import '../widgets/brand_logo_list.dart';

class ShopDetailScreenV2 extends StatefulWidget {
  final String shopId;

  const ShopDetailScreenV2({
    Key? key,
    required this.shopId,
  }) : super(key: key);

  @override
  State<ShopDetailScreenV2> createState() => _ShopDetailScreenV2State();
}

class _ShopDetailScreenV2State extends State<ShopDetailScreenV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ShopService _shopService = ShopService();
  final ReviewService _reviewService = ReviewService();
  final AnnouncementService _announcementService = AnnouncementService();
  
  Shop? _shop;
  ShopRating? _shopRating;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadShopData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShopData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final shop = await _shopService.getShopById(widget.shopId);
      final rating = await _reviewService.getShopRating(widget.shopId);

      if (mounted) {
        setState(() {
          _shop = shop;
          _shopRating = rating;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildShopHeader() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // 이미지 갤러리
          ImageGalleryViewer(
            mainImageUrl: _shop!.imageUrl,
            galleryUrls: _shop!.imageUrls ?? [],
          ),
          
          // 상점 기본 정보
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상점명 및 배지들
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _shop!.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_shop!.isVerified)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // 상점 유형 배지
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getShopTypeColor(_shop!.shopType),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getShopTypeIcon(_shop!.shopType),
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _shop!.shopType.displayName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 영업 상태 (오프라인/하이브리드만)
                              if (_shop!.isOffline || 
                                  _shop!.shopType == ShopType.hybrid)
                                BusinessStatusBadge(shop: _shop!),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 즐겨찾기 버튼
                    FavoriteButton(
                      shopId: _shop!.id,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // 평점 정보
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 20,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _shopRating?.averageRating.toStringAsFixed(1) ?? '0.0',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_shopRating?.reviewCount ?? 0}개 리뷰)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // 설명
                Text(
                  _shop!.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                
                // 주요 브랜드
                if (_shop!.mainBrands.isNotEmpty) ...[
                  const Text(
                    '주요 브랜드',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BrandLogoList(brands: _shop!.mainBrands),
                  const SizedBox(height: 16),
                ],
                
                // 편의시설/서비스 아이콘 행
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (_shop!.parkingAvailable == true)
                      _buildFeatureChip(Icons.local_parking, '주차가능'),
                    if (_shop!.fittingAvailable == true)
                      _buildFeatureChip(Icons.checkroom, '시착가능'),
                    if (_shop!.wheelchairAccessible == true)
                      _buildFeatureChip(Icons.accessible, '휠체어'),
                    if (_shop!.kidsFriendly == true)
                      _buildFeatureChip(Icons.child_friendly, '아동동반'),
                    if (_shop!.sameDayDelivery == true)
                      _buildFeatureChip(Icons.rocket_launch, '당일배송'),
                    if (_shop!.pickupService == true)
                      _buildFeatureChip(Icons.shopping_bag, '픽업가능'),
                    if (_shop!.onlineToOffline == true)
                      _buildFeatureChip(Icons.sync_alt, 'O2O'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPink.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primaryPink,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primaryPink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _shop == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('상점 상세'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? '상점을 찾을 수 없습니다',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadShopData,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(
                  _shop!.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.store,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // TODO: 공유 기능
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // TODO: 더보기 메뉴
                  },
                ),
              ],
            ),
            _buildShopHeader(),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryPink,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primaryPink,
                  tabs: const [
                    Tab(text: '기본정보'),
                    Tab(text: '영업정보'),
                    Tab(text: '브랜드'),
                    Tab(text: '리뷰'),
                    Tab(text: '공지사항'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // 기본정보 탭
            ShopInfoSection(
              shop: _shop!,
              infoType: ShopInfoType.basic,
            ),
            
            // 영업정보 탭
            ShopInfoSection(
              shop: _shop!,
              infoType: ShopInfoType.business,
            ),
            
            // 브랜드/카테고리 탭
            ShopInfoSection(
              shop: _shop!,
              infoType: ShopInfoType.brands,
            ),
            
            // 리뷰 탭
            ReviewListWidget(
              shopId: _shop!.id,
              shopOwnerId: _shop!.ownerId,
            ),
            
            // 공지사항 탭
            AnnouncementListWidget(
              shopId: _shop!.id,
              isOwner: false, // TODO: 실제 소유자 확인
            ),
          ],
        ),
      ),
    );
  }

  Color _getShopTypeColor(ShopType type) {
    switch (type) {
      case ShopType.offline:
        return AppColors.offlineShop;
      case ShopType.online:
        return AppColors.onlineShop;
      case ShopType.hybrid:
        return AppColors.secondaryAccent;
    }
  }

  IconData _getShopTypeIcon(ShopType type) {
    switch (type) {
      case ShopType.offline:
        return Icons.store;
      case ShopType.online:
        return Icons.shopping_cart;
      case ShopType.hybrid:
        return Icons.storefront;
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}