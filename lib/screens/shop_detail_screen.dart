import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../models/review.dart';
import '../theme/app_colors.dart';
import '../widgets/favorite_button.dart';
import '../widgets/review_item.dart';
import '../widgets/rating_summary.dart';
import '../services/review_service.dart';
import '../services/auth_service.dart';
import 'review/write_review_screen.dart';
import 'review_debug_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final Shop shop;
  
  const ShopDetailScreen({
    super.key,
    required this.shop,
  });

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  final _reviewService = ReviewService();
  final _authService = AuthService();
  
  List<Review> _reviews = [];
  ShopRating? _shopRating;
  Review? _userReview;
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      // 리뷰 목록 가져오기
      final reviews = await _reviewService.getShopReviews(widget.shop.id);
      
      // 평점 정보 가져오기
      final rating = await _reviewService.getShopRating(widget.shop.id);
      
      // 현재 사용자의 리뷰 확인
      final user = _authService.currentUser;
      Review? userReview;
      if (user != null) {
        userReview = await _reviewService.getUserReviewForShop(
          user.id,
          widget.shop.id,
        );
      }

      setState(() {
        _reviews = reviews;
        _shopRating = rating;
        _userReview = userReview;
        _isLoadingReviews = false;
      });
    } catch (e) {
      // Error loading reviews: $e
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _navigateToWriteReview() async {
    if (_authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('리뷰를 작성하려면 로그인이 필요합니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          shop: widget.shop,
          existingReview: _userReview,
        ),
      ),
    );

    if (result == true) {
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shop.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 공유 기능 추후 구현
            },
          ),
          FavoriteButton(
            shopId: widget.shop.id,
            size: 24,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상점 이미지
            Stack(
              children: [
                Image.network(
                  widget.shop.imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: AppColors.lightGray,
                      child: const Center(
                        child: Icon(
                          Icons.store,
                          size: 80,
                          color: AppColors.gray,
                        ),
                      ),
                    );
                  },
                ),
                // 상점 타입 배지
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getShopTypeColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getShopTypeIcon(),
                          size: 16,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.shop.shopType.displayName,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 인증 배지
                if (widget.shop.isVerified)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 20,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
            
            // 상점 정보
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 평점 & 리뷰
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.warning, size: 24),
                      const SizedBox(width: 4),
                      Text(
                        _shopRating?.averageRating.toStringAsFixed(1) ?? '0.0',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(리뷰 ${_shopRating?.reviewCount ?? 0}개)',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      if (widget.shop.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(26),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified, size: 16, color: AppColors.success),
                              SizedBox(width: 4),
                              Text(
                                '인증매장',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 설명
                  Text(
                    widget.shop.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  
                  // 리뷰 섹션
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '리뷰',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ReviewDebugScreen(
                                    shopId: widget.shop.id,
                                    shopName: widget.shop.name,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.bug_report, size: 20),
                            color: AppColors.gray,
                          ),
                          TextButton.icon(
                            onPressed: _navigateToWriteReview,
                            icon: Icon(
                              _userReview != null ? Icons.edit : Icons.edit,
                              size: 20,
                            ),
                            label: Text(_userReview != null ? '리뷰 수정' : '리뷰 작성'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryPink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 평점 요약
                  RatingSummary(rating: _shopRating),
                  const SizedBox(height: 16),
                  
                  // 리뷰 목록
                  if (_isLoadingReviews)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: const Center(
                        child: Text(
                          '아직 작성된 리뷰가 없습니다.\n첫 번째 리뷰를 작성해보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.gray,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        return ReviewItem(
                          review: review,
                          onEdit: review.userId == _authService.currentUser?.id
                            ? () => _navigateToWriteReview()
                            : null,
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  
                  // 취급 브랜드
                  Text(
                    '취급 브랜드',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.shop.brands.map((brand) => Chip(
                      label: Text(brand),
                      backgroundColor: AppColors.secondaryPurple,
                      labelStyle: const TextStyle(
                        color: AppColors.secondaryAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // 상점 정보 카드들
                  if (widget.shop.isOffline) ...[
                    _buildInfoCard(
                      context,
                      icon: Icons.location_on,
                      title: '주소',
                      content: widget.shop.address ?? '주소 정보 없음',
                    ),
                    const SizedBox(height: 12),
                    if (widget.shop.phone != null)
                      _buildInfoCard(
                        context,
                        icon: Icons.phone,
                        title: '전화번호',
                        content: widget.shop.phone!,
                      ),
                    const SizedBox(height: 12),
                    if (widget.shop.businessHours != null)
                      _buildInfoCard(
                        context,
                        icon: Icons.access_time,
                        title: '영업시간',
                        content: widget.shop.businessHours!,
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeatureCard(
                            context,
                            icon: Icons.local_parking,
                            label: '주차',
                            available: widget.shop.parkingAvailable ?? false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard(
                            context,
                            icon: Icons.checkroom,
                            label: '시착',
                            available: widget.shop.fittingAvailable ?? false,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (widget.shop.isOnline) ...[
                    if (widget.shop.websiteUrl != null)
                      _buildInfoCard(
                        context,
                        icon: Icons.language,
                        title: '웹사이트',
                        content: widget.shop.websiteUrl!,
                      ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.local_shipping,
                      title: '배송정보',
                      content: widget.shop.hasFreeShipping
                        ? '${(widget.shop.freeShippingMin! / 10000).toStringAsFixed(0)}만원 이상 무료배송'
                        : '배송비 ${widget.shop.shippingFee ?? 0}원',
                    ),
                    if (widget.shop.deliveryInfo != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        icon: Icons.info_outline,
                        title: '배송 안내',
                        content: widget.shop.deliveryInfo!,
                      ),
                    ],
                  ],
                  
                  // 하단 여백
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryPink, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureCard(BuildContext context, {
    required IconData icon,
    required String label,
    required bool available,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: available ? AppColors.success.withAlpha(26) : AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: available ? AppColors.success : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: available ? AppColors.success : AppColors.gray,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: available ? AppColors.success : AppColors.gray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            color: available ? AppColors.success : AppColors.gray,
            size: 16,
          ),
        ],
      ),
    );
  }
  
  Color _getShopTypeColor() {
    switch (widget.shop.shopType) {
      case ShopType.offline:
        return AppColors.offlineShop;
      case ShopType.online:
        return AppColors.onlineShop;
      case ShopType.hybrid:
        return AppColors.secondaryAccent;
    }
  }
  
  IconData _getShopTypeIcon() {
    switch (widget.shop.shopType) {
      case ShopType.offline:
        return Icons.store;
      case ShopType.online:
        return Icons.shopping_cart;
      case ShopType.hybrid:
        return Icons.storefront;
    }
  }
}