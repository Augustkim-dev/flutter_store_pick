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
      body: CustomScrollView(
        slivers: [
          // 앱바 & 이미지
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                shop.name,
                style: const TextStyle(
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    shop.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.lightGray,
                        child: const Icon(
                          Icons.store,
                          size: 80,
                          color: AppColors.gray,
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(102),
                        ],
                      ),
                    ),
                  ),
                ],
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
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  // TODO: 즐겨찾기 기능
                },
              ),
            ],
          ),
          
          // 상세 정보
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상점 유형 & 인증 배지
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getShopTypeColor(shop.shopType),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getShopTypeIcon(shop.shopType),
                              size: 16,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 6),
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
                      const SizedBox(width: 8),
                      if (shop.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(26),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.success),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '인증매장',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 평점 & 리뷰
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < shop.rating.floor() 
                            ? Icons.star 
                            : index < shop.rating 
                              ? Icons.star_half 
                              : Icons.star_border,
                          color: AppColors.warning,
                          size: 20,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        shop.ratingText,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(리뷰 ${shop.reviewCount}개)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // 설명
                  Text(
                    '소개',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shop.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // 오프라인 매장 정보
                  if (shop.isOffline) ...[
                    _buildSectionTitle(context, Icons.location_on, '매장 정보'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        if (shop.address != null)
                          _buildInfoRow(Icons.home, '주소', shop.address!),
                        if (shop.phone != null)
                          _buildInfoRow(Icons.phone, '전화', shop.phone!),
                        if (shop.businessHours != null)
                          _buildInfoRow(Icons.access_time, '영업시간', shop.businessHours!),
                        if (shop.parkingAvailable != null)
                          _buildInfoRow(
                            Icons.local_parking,
                            '주차',
                            shop.parkingAvailable! ? '가능' : '불가능',
                          ),
                        if (shop.fittingAvailable != null)
                          _buildInfoRow(
                            Icons.checkroom,
                            '시착',
                            shop.fittingAvailable! ? '가능' : '불가능',
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // 온라인 쇼핑몰 정보
                  if (shop.isOnline) ...[
                    _buildSectionTitle(context, Icons.shopping_cart, '온라인몰 정보'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        if (shop.websiteUrl != null)
                          _buildInfoRow(Icons.language, '웹사이트', shop.websiteUrl!),
                        if (shop.phone != null)
                          _buildInfoRow(Icons.support_agent, '고객센터', shop.phone!),
                        if (shop.shippingFee != null)
                          _buildInfoRow(
                            Icons.local_shipping,
                            '배송비',
                            shop.shippingFee == 0 
                              ? '무료배송'
                              : '${shop.shippingFee}원',
                          ),
                        if (shop.freeShippingMin != null && shop.freeShippingMin! > 0)
                          _buildInfoRow(
                            Icons.card_giftcard,
                            '무료배송 조건',
                            '${(shop.freeShippingMin! / 10000).toStringAsFixed(0)}만원 이상',
                          ),
                        if (shop.deliveryInfo != null)
                          _buildInfoRow(Icons.schedule, '배송정보', shop.deliveryInfo!),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // 취급 브랜드
                  _buildSectionTitle(context, Icons.style, '취급 브랜드'),
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
                  
                  // 취급 카테고리
                  _buildSectionTitle(context, Icons.category, '주요 상품'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: shop.categories.map((category) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gray),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.darkGray,
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 40),
                  
                  // 액션 버튼들
                  if (shop.isOffline)
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 지도 앱 연동
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('길찾기'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  if (shop.isOnline)
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 웹사이트 열기
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('웹사이트 방문'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  if (shop.phone != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: 전화 걸기
                      },
                      icon: const Icon(Icons.call),
                      label: Text('전화 문의 (${shop.phone})'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
  
  Widget _buildInfoCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.gray),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.gray,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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