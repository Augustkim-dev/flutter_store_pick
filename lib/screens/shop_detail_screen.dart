import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../theme/app_colors.dart';

class ShopDetailScreen extends StatelessWidget {
  final Shop shop;
  
  const ShopDetailScreen({
    super.key,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name),
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
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // 즐겨찾기 기능 추후 구현
            },
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
                  shop.imageUrl,
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
                          shop.shopType.displayName,
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
                if (shop.isVerified)
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
                        shop.ratingText,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(리뷰 ${shop.reviewCount}개)',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      if (shop.isVerified)
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
                    shop.description,
                    style: Theme.of(context).textTheme.bodyLarge,
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
                    children: shop.brands.map((brand) => Chip(
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
                  if (shop.isOffline) ...[
                    _buildInfoCard(
                      context,
                      icon: Icons.location_on,
                      title: '주소',
                      content: shop.address ?? '주소 정보 없음',
                    ),
                    const SizedBox(height: 12),
                    if (shop.phone != null)
                      _buildInfoCard(
                        context,
                        icon: Icons.phone,
                        title: '전화번호',
                        content: shop.phone!,
                      ),
                    const SizedBox(height: 12),
                    if (shop.businessHours != null)
                      _buildInfoCard(
                        context,
                        icon: Icons.access_time,
                        title: '영업시간',
                        content: shop.businessHours!,
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeatureCard(
                            context,
                            icon: Icons.local_parking,
                            label: '주차',
                            available: shop.parkingAvailable ?? false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard(
                            context,
                            icon: Icons.checkroom,
                            label: '시착',
                            available: shop.fittingAvailable ?? false,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (shop.isOnline) ...[
                    if (shop.websiteUrl != null)
                      _buildInfoCard(
                        context,
                        icon: Icons.language,
                        title: '웹사이트',
                        content: shop.websiteUrl!,
                      ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.local_shipping,
                      title: '배송정보',
                      content: shop.hasFreeShipping
                        ? '${(shop.freeShippingMin! / 10000).toStringAsFixed(0)}만원 이상 무료배송'
                        : '배송비 ${shop.shippingFee ?? 0}원',
                    ),
                    if (shop.deliveryInfo != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        icon: Icons.info_outline,
                        title: '배송 안내',
                        content: shop.deliveryInfo!,
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
    switch (shop.shopType) {
      case ShopType.offline:
        return AppColors.offlineShop;
      case ShopType.online:
        return AppColors.onlineShop;
      case ShopType.hybrid:
        return AppColors.secondaryAccent;
    }
  }
  
  IconData _getShopTypeIcon() {
    switch (shop.shopType) {
      case ShopType.offline:
        return Icons.store;
      case ShopType.online:
        return Icons.shopping_cart;
      case ShopType.hybrid:
        return Icons.storefront;
    }
  }
}