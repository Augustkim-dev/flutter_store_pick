import 'package:flutter/material.dart';
import 'dart:async';
import '../models/shop.dart';
import '../services/dashboard_service.dart';
import '../widgets/dashboard/event_carousel_widget.dart';
import '../widgets/dashboard/new_shops_widget.dart';
import '../widgets/dashboard/recent_announcements_widget.dart';
import '../widgets/dashboard/quick_stats_widget.dart';
import '../widgets/skeleton/dashboard_skeletons.dart';
import '../widgets/error_widget_custom.dart';
import '../theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  final DashboardService _dashboardService = DashboardService();
  Stream<DashboardData>? _dataStream;
  StreamController<DashboardData>? _streamController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initDataStream();
  }
  
  void _initDataStream({bool forceRefresh = false}) {
    _streamController?.close();
    _streamController = StreamController<DashboardData>.broadcast();
    
    // Subscribe to the progressive loading stream
    _dashboardService.getDashboardDataProgressive(forceRefresh: forceRefresh).listen(
      (data) {
        if (!_streamController!.isClosed) {
          _streamController!.add(data);
        }
      },
      onError: (error) {
        if (!_streamController!.isClosed) {
          _streamController!.addError(error);
        }
      },
    );
    
    setState(() {
      _dataStream = _streamController!.stream;
    });
  }

  @override
  void dispose() {
    _streamController?.close();
    super.dispose();
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
      body: _dataStream == null 
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<DashboardData>(
            stream: _dataStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return CustomErrorWidget(
                  message: '대시보드 데이터를 불러오는데 실패했습니다.',
                  errorType: ErrorType.network,
                  onRetry: () => _initDataStream(forceRefresh: true),
                );
              }
              
              if (!snapshot.hasData) {
                // Show skeleton while loading
                return const DashboardSkeleton();
              }
              
              final data = snapshot.data!;
              return _buildDashboardContent(data);
            },
          ),
    );
  }

  Widget _buildDashboardContent(DashboardData data) {
    return RefreshIndicator(
      onRefresh: () async {
        _initDataStream(forceRefresh: true);
      },
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

          // Quick stats (show skeleton only while loading)
          SliverToBoxAdapter(
            child: data.sectionLoadingStatus['stats'] == true
              ? QuickStatsWidget(stats: data.stats)
              : const QuickStatsSkeleton(),
          ),

          // Featured events carousel
          if (data.featuredEvents.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: EventCarouselWidget(events: data.featuredEvents),
              ),
            )
          else if (data.sectionLoadingStatus['events'] != true)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: EventCarouselSkeleton(),
              ),
            ),

          // New shops (show skeleton only while loading)
          if (data.newShops.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: NewShopsWidget(shops: data.newShops),
              ),
            )
          else if (data.sectionLoadingStatus['newShops'] != true)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: NewShopsSkeleton(),
              ),
            ),

          // Popular shops
          if (data.popularShops.isNotEmpty) 
            SliverToBoxAdapter(child: _buildPopularShops(data)),

          // Recent announcements (show skeleton only while loading)
          if (data.recentAnnouncements.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: RecentAnnouncementsWidget(announcements: data.recentAnnouncements),
              ),
            )
          else if (data.sectionLoadingStatus['announcements'] != true)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: AnnouncementsSkeleton(),
              ),
            ),

          // Favorite shops quick access
          if (data.favoriteShops.isNotEmpty) 
            SliverToBoxAdapter(child: _buildFavoriteShops(data)),

          // Show empty state message if loading is complete but no data
          if (data.isLoadingComplete && 
              data.featuredEvents.isEmpty && 
              data.newShops.isEmpty && 
              data.recentAnnouncements.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '아직 표시할 콘텐츠가 없습니다',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '곧 새로운 콘텐츠가 추가될 예정입니다',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildPopularShops(DashboardData data) {
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
          itemCount: data.popularShops.length,
          itemBuilder: (context, index) {
            final shop = data.popularShops[index];
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

  Widget _buildFavoriteShops(DashboardData data) {
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
            itemCount: data.favoriteShops.length,
            itemBuilder: (context, index) {
              final shop = data.favoriteShops[index];
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
