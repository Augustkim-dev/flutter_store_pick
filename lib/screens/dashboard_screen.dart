import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../services/dashboard_service.dart';
import '../widgets/dashboard/event_carousel_widget.dart';
import '../widgets/dashboard/new_shops_widget.dart';
import '../widgets/dashboard/recent_announcements_widget.dart';
import '../widgets/dashboard/quick_stats_widget.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_widget_custom.dart';
import '../theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  final DashboardService _dashboardService = DashboardService();
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _dashboardService.getDashboardData(forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '대시보드 데이터를 불러오는데 실패했습니다.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/app_icon.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.sports_gymnastics, color: AppColors.primaryPink);
              },
            ),
            const SizedBox(width: 8),
            const Text('발레플러스'),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return CustomErrorWidget(
        message: _errorMessage,
        errorType: ErrorType.network,
        onRetry: () => _loadDashboardData(),
      );
    }

    if (_dashboardData == null) {
      return EmptyStateWidget(
        title: '데이터가 없습니다',
        message: '표시할 대시보드 데이터가 없습니다.',
        icon: Icons.dashboard_outlined,
        action: ElevatedButton(onPressed: () => _loadDashboardData(), child: const Text('다시 시도')),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDashboardData(forceRefresh: true),
      child: CustomScrollView(
        slivers: [
          // Welcome message
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요! 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '오늘도 완벽한 발레 용품을 찾아보세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          // Quick stats
          SliverToBoxAdapter(child: QuickStatsWidget(stats: _dashboardData!.stats)),

          // Featured events carousel
          if (_dashboardData!.featuredEvents.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: EventCarouselWidget(events: _dashboardData!.featuredEvents),
              ),
            ),

          // New shops
          if (_dashboardData!.newShops.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: NewShopsWidget(shops: _dashboardData!.newShops),
              ),
            ),

          // Popular shops
          if (_dashboardData!.popularShops.isNotEmpty) SliverToBoxAdapter(child: _buildPopularShops()),

          // Recent announcements
          if (_dashboardData!.recentAnnouncements.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: RecentAnnouncementsWidget(announcements: _dashboardData!.recentAnnouncements),
              ),
            ),

          // Favorite shops quick access
          if (_dashboardData!.favoriteShops.isNotEmpty) SliverToBoxAdapter(child: _buildFavoriteShops()),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome message skeleton
        const SkeletonLoader(height: 30, width: 150),
        const SizedBox(height: 8),
        const SkeletonLoader(height: 20, width: 200),
        const SizedBox(height: 20),

        // Stats skeleton
        const SkeletonLoader(height: 150, width: double.infinity),
        const SizedBox(height: 20),

        // Event carousel skeleton
        const SkeletonLoader(height: 200, width: double.infinity),
        const SizedBox(height: 20),

        // Shops skeleton
        Row(
          children: List.generate(
            3,
            (index) => const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: SkeletonLoader(height: 120, width: double.infinity),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularShops() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(color: AppColors.primaryPink, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(
                '인기 상점 TOP 5',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.whatshot, color: Colors.orange, size: 20),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _dashboardData!.popularShops.length,
          itemBuilder: (context, index) {
            final shop = _dashboardData!.popularShops[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryPink.withAlpha(26),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink),
                ),
              ),
              title: Text(shop.name),
              subtitle: Text(
                shop.shopType.displayName,
                style: TextStyle(fontSize: 12, color: _getShopTypeColor(shop.shopType)),
              ),
              trailing: SizedBox(
                width: 60,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        shop.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                Navigator.of(context).pushNamed('/shop-detail', arguments: shop.id);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFavoriteShops() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(color: AppColors.primaryPink, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text('즐겨찾기한 상점', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Icon(Icons.favorite, color: Colors.red, size: 18),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _dashboardData!.favoriteShops.length,
            itemBuilder: (context, index) {
              final shop = _dashboardData!.favoriteShops[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed('/shop-detail', arguments: shop.id);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withAlpha(51)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.store, color: _getShopTypeColor(shop.shopType), size: 20),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            shop.name,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getShopTypeColor(ShopType type) {
    switch (type) {
      case ShopType.offline:
        return AppColors.offlineShop;
      case ShopType.online:
        return AppColors.onlineShop;
      case ShopType.hybrid:
        return AppColors.primaryPink;
    }
  }
}
