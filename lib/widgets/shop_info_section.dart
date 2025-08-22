import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/shop.dart';
import '../theme/app_colors.dart';

enum ShopInfoType {
  basic,
  business,
  brands,
}

class ShopInfoSection extends StatelessWidget {
  final Shop shop;
  final ShopInfoType infoType;

  const ShopInfoSection({
    Key? key,
    required this.shop,
    required this.infoType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildContent(context),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    switch (infoType) {
      case ShopInfoType.basic:
        return _buildBasicInfo(context);
      case ShopInfoType.business:
        return _buildBusinessInfo(context);
      case ShopInfoType.brands:
        return _buildBrandsInfo(context);
    }
  }

  List<Widget> _buildBasicInfo(BuildContext context) {
    return [
      _buildInfoItem(
        icon: Icons.phone,
        title: '전화번호',
        content: shop.phone ?? '정보 없음',
        onTap: shop.phone != null
            ? () {
                Clipboard.setData(ClipboardData(text: shop.phone!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('전화번호가 복사되었습니다')),
                );
              }
            : null,
      ),
      const Divider(),
      _buildInfoItem(
        icon: Icons.email,
        title: '이메일',
        content: shop.email ?? '정보 없음',
        onTap: shop.email != null
            ? () {
                Clipboard.setData(ClipboardData(text: shop.email!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이메일이 복사되었습니다')),
                );
              }
            : null,
      ),
      const Divider(),
      _buildInfoItem(
        icon: Icons.chat,
        title: '카카오톡',
        content: shop.kakaoId ?? '정보 없음',
      ),
      const Divider(),
      if (shop.isOffline) ...[
        _buildInfoItem(
          icon: Icons.location_on,
          title: '주소',
          content: shop.address ?? '정보 없음',
          subtitle: shop.detailedLocation,
          onTap: shop.address != null
              ? () {
                  Clipboard.setData(ClipboardData(text: shop.address!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('주소가 복사되었습니다')),
                  );
                }
              : null,
        ),
        const Divider(),
      ],
      if (shop.isOnline) ...[
        _buildInfoItem(
          icon: Icons.language,
          title: '웹사이트',
          content: shop.websiteUrl ?? '정보 없음',
          isLink: true,
        ),
        const Divider(),
      ],
      if (shop.businessNumber != null) ...[
        _buildInfoItem(
          icon: Icons.badge,
          title: '사업자등록번호',
          content: shop.businessNumber!,
        ),
      ],
    ];
  }

  List<Widget> _buildBusinessInfo(BuildContext context) {
    final widgets = <Widget>[];

    // 오프라인 영업 정보
    if (shop.isOffline) {
      widgets.addAll([
        _buildSectionTitle('영업 정보'),
        const SizedBox(height: 8),
        _buildInfoItem(
          icon: Icons.access_time,
          title: '영업시간',
          content: shop.businessHours ?? '정보 없음',
        ),
        const Divider(),
        if (shop.lunchBreakStart != null && shop.lunchBreakEnd != null) ...[
          _buildInfoItem(
            icon: Icons.lunch_dining,
            title: '점심시간',
            content: '${shop.lunchBreakStart} - ${shop.lunchBreakEnd}',
          ),
          const Divider(),
        ],
        const SizedBox(height: 16),
        _buildSectionTitle('편의시설'),
        const SizedBox(height: 8),
        _buildFacilityInfo(),
        const SizedBox(height: 16),
        if (shop.directionsPublic != null || shop.directionsWalking != null) ...[
          _buildSectionTitle('오시는 길'),
          const SizedBox(height: 8),
          if (shop.directionsPublic != null)
            _buildInfoItem(
              icon: Icons.directions_subway,
              title: '대중교통',
              content: shop.directionsPublic!,
            ),
          if (shop.directionsWalking != null) ...[
            const SizedBox(height: 8),
            _buildInfoItem(
              icon: Icons.directions_walk,
              title: '도보',
              content: shop.directionsWalking!,
            ),
          ],
          const Divider(),
        ],
      ]);
    }

    // 온라인 영업 정보
    if (shop.isOnline) {
      widgets.addAll([
        _buildSectionTitle('배송 정보'),
        const SizedBox(height: 8),
        _buildInfoItem(
          icon: Icons.local_shipping,
          title: '배송비',
          content: shop.shippingFee != null
              ? '${shop.shippingFee}원'
              : '정보 없음',
          subtitle: shop.hasFreeShipping
              ? '${(shop.freeShippingMin! / 10000).toStringAsFixed(0)}만원 이상 무료배송'
              : null,
        ),
        const Divider(),
        if (shop.deliveryInfo != null) ...[
          _buildInfoItem(
            icon: Icons.info_outline,
            title: '배송 안내',
            content: shop.deliveryInfo!,
          ),
          const Divider(),
        ],
        const SizedBox(height: 16),
        _buildSectionTitle('고객센터'),
        const SizedBox(height: 8),
        if (shop.csHours != null)
          _buildInfoItem(
            icon: Icons.schedule,
            title: '운영시간',
            content: shop.csHours!,
          ),
        if (shop.csPhone != null) ...[
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.support_agent,
            title: '전화',
            content: shop.csPhone!,
          ),
        ],
        if (shop.csKakao != null) ...[
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.chat,
            title: '카카오톡',
            content: shop.csKakao!,
          ),
        ],
        if (shop.csEmail != null) ...[
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.email,
            title: '이메일',
            content: shop.csEmail!,
          ),
        ],
        const Divider(),
        const SizedBox(height: 16),
        _buildSectionTitle('교환/환불'),
        const SizedBox(height: 8),
        if (shop.exchangePolicy != null)
          _buildInfoItem(
            icon: Icons.swap_horiz,
            title: '교환 정책',
            content: shop.exchangePolicy!,
          ),
        if (shop.refundPolicy != null) ...[
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.keyboard_return,
            title: '환불 정책',
            content: shop.refundPolicy!,
          ),
        ],
        if (shop.returnShippingFee != null) ...[
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.attach_money,
            title: '반품 배송비',
            content: '${shop.returnShippingFee}원 (편도)',
          ),
        ],
      ]);
    }

    // 복합 상점 특수 기능
    if (shop.shopType == ShopType.hybrid) {
      widgets.addAll([
        const SizedBox(height: 16),
        _buildSectionTitle('특별 서비스'),
        const SizedBox(height: 8),
        if (shop.pickupService == true)
          _buildInfoItem(
            icon: Icons.shopping_bag,
            title: '매장 픽업',
            content: '온라인 주문 후 매장에서 수령 가능',
          ),
        if (shop.onlineToOffline == true) ...[
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.sync_alt,
            title: 'O2O 서비스',
            content: '온라인 주문 → 오프라인 체험/수령',
          ),
        ],
      ]);
    }

    return widgets.isNotEmpty
        ? widgets
        : [
            const Center(
              child: Text('영업 정보가 없습니다'),
            ),
          ];
  }

  List<Widget> _buildBrandsInfo(BuildContext context) {
    final widgets = <Widget>[];

    if (shop.mainBrands.isNotEmpty) {
      widgets.addAll([
        _buildSectionTitle('취급 브랜드'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: shop.mainBrands.map((brand) {
            return Chip(
              label: Text(brand),
              backgroundColor: AppColors.secondaryPurple,
              labelStyle: const TextStyle(
                color: AppColors.secondaryAccent,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
      ]);
    }

    if (shop.categories.isNotEmpty) {
      widgets.addAll([
        const SizedBox(height: 24),
        _buildSectionTitle('전문 카테고리'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: shop.categories.map((category) {
            return Chip(
              label: Text(category),
              backgroundColor: AppColors.primaryPink.withValues(alpha: 0.1),
              labelStyle: const TextStyle(
                color: AppColors.primaryPink,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
      ]);
    }

    return widgets.isNotEmpty
        ? widgets
        : [
            const Center(
              child: Text('브랜드 정보가 없습니다'),
            ),
          ];
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String content,
    String? subtitle,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.gray,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isLink ? AppColors.primaryPink : null,
                      decoration: isLink ? TextDecoration.underline : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.copy,
                size: 16,
                color: AppColors.gray,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityInfo() {
    final facilities = <Widget>[];
    
    if (shop.parkingAvailable == true) {
      facilities.add(_buildFacilityChip(Icons.local_parking, '주차 가능'));
    }
    if (shop.fittingAvailable == true) {
      facilities.add(_buildFacilityChip(Icons.checkroom, '시착 가능'));
    }
    if (shop.wheelchairAccessible == true) {
      facilities.add(_buildFacilityChip(Icons.accessible, '휠체어 접근'));
    }
    if (shop.kidsFriendly == true) {
      facilities.add(_buildFacilityChip(Icons.child_friendly, '아동 동반'));
    }
    
    if (facilities.isEmpty) {
      return const Text('편의시설 정보 없음');
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: facilities,
    );
  }

  Widget _buildFacilityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}