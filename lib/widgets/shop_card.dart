import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../models/review.dart';
import '../theme/app_colors.dart';
import '../services/review_service.dart';
import 'favorite_button.dart';
import '../utils/app_logger.dart';
import '../utils/business_hours_parser.dart';

class ShopCard extends StatefulWidget {
  final Shop shop;
  final VoidCallback onTap;
  final String? searchQuery;
  final ShopRating? shopRating;
  
  const ShopCard({
    super.key,
    required this.shop,
    required this.onTap,
    this.searchQuery,
    this.shopRating,
  });

  @override
  State<ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<ShopCard> {
  final _reviewService = ReviewService();
  ShopRating? _shopRating;

  @override
  void initState() {
    super.initState();
    _shopRating = widget.shopRating;
    if (_shopRating == null) {
      _loadRating();
    }
  }

  @override
  void didUpdateWidget(ShopCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shopRating != oldWidget.shopRating) {
      setState(() {
        _shopRating = widget.shopRating;
      });
    }
  }

  Future<void> _loadRating() async {
    final rating = await _reviewService.getShopRating(widget.shop.id);
    if (mounted) {
      setState(() {
        _shopRating = rating;
      });
    }
  }

  // 영업 상태 확인
  bool _isOpenNow() {
    return BusinessHoursParser.isOpenNow(widget.shop.businessHours);
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.shop.isOffline || widget.shop.shopType == ShopType.hybrid 
        ? _isOpenNow() 
        : true;

    return GestureDetector(
      onTap: () {
        AppLogger.d('ShopCard tapped: ${widget.shop.name} (id: ${widget.shop.id})');
        widget.onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 섹션
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    widget.shop.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        color: AppColors.lightGray,
                        child: const Center(
                          child: Icon(
                            Icons.store,
                            size: 60,
                            color: AppColors.gray,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 상점 유형 배지 & 영업 상태
                Positioned(
                  top: 12,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getShopTypeColor(widget.shop.shopType),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getShopTypeIcon(widget.shop.shopType),
                              size: 14,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.shop.shopType.displayName,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.shop.isOffline || widget.shop.shopType == ShopType.hybrid) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOpen ? Icons.access_time : Icons.block,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOpen ? '영업중' : '휴무',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 인증 배지
                if (widget.shop.isVerified)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
            
            // 정보 섹션
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상점명
                  Row(
                    children: [
                      Expanded(
                        child: _buildHighlightedText(
                          context,
                          widget.shop.name,
                          widget.searchQuery,
                          Theme.of(context).textTheme.titleLarge!,
                        ),
                      ),
                      // 즐겨찾기 버튼
                      FavoriteButton(
                        shopId: widget.shop.id,
                        size: 20,
                      ),
                      // 평점
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _shopRating?.averageRating.toStringAsFixed(1) ?? '0.0',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' (${_shopRating?.reviewCount ?? 0})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // 설명
                  _buildHighlightedText(
                    context,
                    widget.shop.description,
                    widget.searchQuery,
                    Theme.of(context).textTheme.bodyMedium!,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  
                  // 위치 또는 배송 정보 & 편의시설 아이콘
                  Row(
                    children: [
                      Icon(
                        widget.shop.isOffline ? Icons.location_on : Icons.local_shipping,
                        size: 16,
                        color: AppColors.gray,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.shop.isOffline 
                            ? (widget.shop.address ?? '위치 정보 없음')
                            : widget.shop.hasFreeShipping
                              ? '${(widget.shop.freeShippingMin! / 10000).toStringAsFixed(0)}만원 이상 무료배송'
                              : '배송비 ${widget.shop.shippingFee ?? 0}원',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 편의시설 아이콘
                      if (widget.shop.parkingAvailable == true)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.local_parking,
                            size: 16,
                            color: AppColors.success,
                          ),
                        ),
                      if (widget.shop.fittingAvailable == true)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.checkroom,
                            size: 16,
                            color: AppColors.primaryPink,
                          ),
                        ),
                      if (widget.shop.sameDayDelivery == true)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.rocket_launch,
                            size: 16,
                            color: AppColors.warning,
                          ),
                        ),
                      if (widget.shop.pickupService == true)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.shopping_bag,
                            size: 16,
                            color: AppColors.info,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // 브랜드 태그들
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.shop.mainBrands.map((brand) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildHighlightedText(
                        context,
                        brand,
                        widget.searchQuery,
                        const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
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
  
  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String? query,
    TextStyle style, {
    int maxLines = 1,
  }) {
    if (query == null || query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);
    
    if (startIndex == -1) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    final endIndex = startIndex + query.length;
    final beforeMatch = text.substring(0, startIndex);
    final match = text.substring(startIndex, endIndex);
    final afterMatch = text.substring(endIndex);
    
    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: beforeMatch),
          TextSpan(
            text: match,
            style: style.copyWith(
              backgroundColor: AppColors.primaryPink.withAlpha(51),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: afterMatch),
        ],
      ),
    );
  }
}