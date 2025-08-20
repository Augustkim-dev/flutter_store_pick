import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/shop.dart';
import '../../models/review.dart';
import '../../services/shop_service.dart';
import '../../services/review_service.dart';
import '../../services/review_reply_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/review_item.dart';
import '../../widgets/review_reply_dialog.dart';
import 'business_hours_edit_screen.dart';
import 'announcement_list_screen.dart';

class ShopDashboardScreen extends StatefulWidget {
  final Shop shop;

  const ShopDashboardScreen({super.key, required this.shop});

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ShopService _shopService = ShopService();
  final ReviewService _reviewService = ReviewService();
  final ReviewReplyService _replyService = ReviewReplyService();

  Map<String, dynamic> _shopStats = {};
  List<Review> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _shopService.setSupabaseMode(true);
    _reviewService.setSupabaseMode(true);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 상점 통계 가져오기
      final stats = await _shopService.getShopStats(widget.shop.id);
      
      // 리뷰 목록 가져오기 (답글 포함)
      final reviews = await _replyService.getShopReviewsWithReplies(widget.shop.id);

      setState(() {
        _shopStats = stats;
        _reviews = reviews;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로딩 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.shop.name} 대시보드'),
        backgroundColor: AppColors.primaryPink,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '통계', icon: Icon(Icons.analytics)),
            Tab(text: '리뷰', icon: Icon(Icons.rate_review)),
            Tab(text: '설정', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildReviewsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final reviewCount = _shopStats['review_count'] ?? 0;
    final averageRating = (_shopStats['average_rating'] ?? 0.0).toDouble();
    final favoriteCount = _shopStats['favorite_count'] ?? 0;
    final weeklyReviews = _shopStats['weekly_reviews'] ?? 0;
    final monthlyReviews = _shopStats['monthly_reviews'] ?? 0;
    final unansweredReviews = _shopStats['unanswered_reviews_count'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 주요 통계 카드
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                const Text(
                  '주요 통계',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      Icons.star,
                      averageRating.toStringAsFixed(1),
                      '평균 평점',
                      Colors.amber,
                    ),
                    _buildStatCard(
                      Icons.rate_review,
                      reviewCount.toString(),
                      '전체 리뷰',
                      Colors.blue,
                    ),
                    _buildStatCard(
                      Icons.favorite,
                      favoriteCount.toString(),
                      '즐겨찾기',
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      Icons.trending_up,
                      weeklyReviews.toString(),
                      '주간 리뷰',
                      Colors.green,
                    ),
                    _buildStatCard(
                      Icons.calendar_month,
                      monthlyReviews.toString(),
                      '월간 리뷰',
                      Colors.purple,
                    ),
                    _buildStatCard(
                      Icons.reply_outlined,
                      unansweredReviews.toString(),
                      '미답변',
                      Colors.orange,
                    ),
                  ],
                ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 평점 분포 차트
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                const Text(
                  '평점 분포',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: reviewCount.toDouble() > 0 ? reviewCount.toDouble() : 10,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${5 - groupIndex}점\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: '${rod.toY.toInt()}개',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const ratings = ['5점', '4점', '3점', '2점', '1점'];
                              return Text(
                                ratings[value.toInt()],
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value == value.toInt()) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(5, (index) {
                        final rating = 5 - index;
                        final count = _reviews.where((r) => r.rating == rating).length;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: count.toDouble(),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryPink,
                                  AppColors.primaryPink.withAlpha(179),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 40,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 평점 요약
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            '평균 평점',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade300),
                      Column(
                        children: [
                          const Text(
                            '답글률',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reviewCount > 0 
                              ? '${((reviewCount - unansweredReviews) / reviewCount * 100).toStringAsFixed(0)}%'
                              : '0%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: reviewCount > 0 && ((reviewCount - unansweredReviews) / reviewCount) >= 0.8
                                ? Colors.green
                                : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 리뷰가 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ReviewItem(
              review: review,
              isShopOwnerView: true,
              onReply: review.hasReply ? () => _showReplyDialog(review) : () => _showReplyDialog(review),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('영업시간 설정'),
                subtitle: Text(
                  widget.shop.isOffline ? '매장 영업시간을 설정하세요' : '온라인 상점은 설정 불필요',
                ),
                trailing: const Icon(Icons.chevron_right),
                enabled: widget.shop.isOffline,
                onTap: widget.shop.isOffline
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessHoursEditScreen(
                              shopId: widget.shop.id,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.announcement),
                title: const Text('공지사항 관리'),
                subtitle: const Text('상점 공지사항을 관리하세요'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnnouncementListScreen(
                        shopId: widget.shop.id,
                        shopName: widget.shop.name,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('취급 브랜드 관리'),
                subtitle: const Text('판매 브랜드를 관리하세요'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('브랜드 관리 기능은 준비 중입니다'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('상점 이미지 관리'),
                subtitle: const Text('상점 대표 이미지를 변경하세요'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('이미지 관리 기능은 준비 중입니다'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('알림 설정'),
                subtitle: const Text('새 리뷰, 문의 알림을 받으세요'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('알림 설정 기능은 준비 중입니다'),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('상점 공개 설정'),
                subtitle: const Text('상점을 검색 결과에 표시'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('공개 설정 기능은 준비 중입니다'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.red.shade50,
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red.shade700),
            title: Text(
              '상점 삭제',
              style: TextStyle(color: Colors.red.shade700),
            ),
            subtitle: const Text('이 작업은 되돌릴 수 없습니다'),
            onTap: () {
              _showDeleteConfirmDialog();
            },
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상점 삭제'),
        content: const Text('정말로 이 상점을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('상점 삭제 기능은 준비 중입니다'),
                ),
              );
            },
            child: Text(
              '삭제',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(Review review) {
    showDialog(
      context: context,
      builder: (context) => ReviewReplyDialog(
        review: review,
        shopId: widget.shop.id,
        onReplySaved: () {
          // 답글 저장 후 데이터 새로고침
          _loadData();
        },
      ),
    );
  }
}