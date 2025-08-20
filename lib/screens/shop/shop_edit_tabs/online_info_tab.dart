import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/shop.dart';
import '../../../models/shipping_region.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shipping_region_widget.dart';

class OnlineInfoTab extends StatefulWidget {
  final Shop shop;
  final TextEditingController websiteController;
  final TextEditingController shippingFeeController;
  final TextEditingController freeShippingMinController;
  final TextEditingController deliveryInfoController;
  final TextEditingController csHoursController;
  final TextEditingController csPhoneController;
  final TextEditingController csKakaoController;
  final TextEditingController csEmailController;
  final TextEditingController exchangePolicyController;
  final TextEditingController refundPolicyController;
  final TextEditingController returnShippingFeeController;
  final bool mobileWebSupport;
  final bool sameDayDelivery;
  final List<String> paymentMethods;
  final ValueChanged<bool> onMobileWebChanged;
  final ValueChanged<bool> onSameDayChanged;
  final ValueChanged<List<String>> onPaymentMethodsChanged;

  const OnlineInfoTab({
    Key? key,
    required this.shop,
    required this.websiteController,
    required this.shippingFeeController,
    required this.freeShippingMinController,
    required this.deliveryInfoController,
    required this.csHoursController,
    required this.csPhoneController,
    required this.csKakaoController,
    required this.csEmailController,
    required this.exchangePolicyController,
    required this.refundPolicyController,
    required this.returnShippingFeeController,
    required this.mobileWebSupport,
    required this.sameDayDelivery,
    required this.paymentMethods,
    required this.onMobileWebChanged,
    required this.onSameDayChanged,
    required this.onPaymentMethodsChanged,
  }) : super(key: key);

  @override
  State<OnlineInfoTab> createState() => _OnlineInfoTabState();
}

class _OnlineInfoTabState extends State<OnlineInfoTab> {
  List<ShippingRegion> _shippingRegions = [];
  
  static const List<String> _availablePaymentMethods = [
    '신용카드',
    '체크카드',
    '계좌이체',
    '가상계좌',
    '휴대폰결제',
    '카카오페이',
    '네이버페이',
    '토스페이',
    '페이코',
    'Apple Pay',
  ];

  @override
  Widget build(BuildContext context) {
    // 온라인이나 복합 상점이 아닌 경우 안내 메시지
    if (!widget.shop.isOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.language_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '온라인 쇼핑몰 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '온라인 또는 온/오프라인 상점만 입력 가능합니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 웹사이트 정보
          _buildSectionTitle('웹사이트 정보'),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.websiteController,
            decoration: const InputDecoration(
              labelText: '웹사이트 URL',
              hintText: 'https://www.example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.language),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('모바일 웹 지원'),
                  subtitle: const Text('모바일 기기에서도 편하게 쇼핑 가능'),
                  value: widget.mobileWebSupport,
                  onChanged: widget.onMobileWebChanged,
                  secondary: const Icon(Icons.phone_android),
                  activeColor: AppColors.primaryPink,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('당일배송 가능'),
                  subtitle: const Text('특정 지역 당일배송 서비스 제공'),
                  value: widget.sameDayDelivery,
                  onChanged: widget.onSameDayChanged,
                  secondary: const Icon(Icons.rocket_launch),
                  activeColor: AppColors.primaryPink,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 배송 정보
          _buildSectionTitle('배송 정보'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.shippingFeeController,
                  decoration: const InputDecoration(
                    labelText: '기본 배송비',
                    hintText: '3000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_shipping),
                    suffixText: '원',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: widget.freeShippingMinController,
                  decoration: const InputDecoration(
                    labelText: '무료배송 최소금액',
                    hintText: '50000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.card_giftcard),
                    suffixText: '원',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.deliveryInfoController,
            decoration: const InputDecoration(
              labelText: '배송 안내',
              hintText: '예: 평균 2-3일 소요, 제주/도서산간 추가비용',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.info_outline),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // 지역별 배송비
          _buildSectionTitle('지역별 배송비'),
          const SizedBox(height: 12),
          ShippingRegionWidget(
            shopId: widget.shop.id,
            regions: _shippingRegions,
            onRegionsChanged: (regions) {
              setState(() {
                _shippingRegions = regions;
              });
            },
          ),
          const SizedBox(height: 24),

          // 결제 수단
          _buildSectionTitle('결제 수단'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availablePaymentMethods.map((method) {
                  final isSelected = widget.paymentMethods.contains(method);
                  return FilterChip(
                    label: Text(method),
                    selected: isSelected,
                    onSelected: (selected) {
                      final newMethods = List<String>.from(widget.paymentMethods);
                      if (selected) {
                        newMethods.add(method);
                      } else {
                        newMethods.remove(method);
                      }
                      widget.onPaymentMethodsChanged(newMethods);
                    },
                    selectedColor: AppColors.primaryPink.withOpacity(0.2),
                    checkmarkColor: AppColors.primaryPink,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 고객센터 정보
          _buildSectionTitle('고객센터 정보'),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.csHoursController,
            decoration: const InputDecoration(
              labelText: '운영시간',
              hintText: '평일 09:00-18:00 (점심 12:00-13:00)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.schedule),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.csPhoneController,
            decoration: const InputDecoration(
              labelText: '고객센터 전화',
              hintText: '1588-0000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.support_agent),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.csKakaoController,
            decoration: const InputDecoration(
              labelText: '카카오톡 채널',
              hintText: '@example',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.chat),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.csEmailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              hintText: 'cs@example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),

          // 교환/환불 정책
          _buildSectionTitle('교환/환불 정책'),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.exchangePolicyController,
            decoration: const InputDecoration(
              labelText: '교환 정책',
              hintText: '상품 수령 후 7일 이내 교환 가능...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.refundPolicyController,
            decoration: const InputDecoration(
              labelText: '환불 정책',
              hintText: '단순 변심의 경우 왕복 배송비 고객 부담...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.returnShippingFeeController,
            decoration: const InputDecoration(
              labelText: '반품 배송비',
              hintText: '6000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.keyboard_return),
              suffixText: '원',
              helperText: '편도 기준',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          const SizedBox(height: 32),

          // 도움말
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.eco_outlined,
                  size: 20,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '온라인 쇼핑몰 운영 Tip',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• 명확한 배송/환불 정책은 고객 신뢰를 높입니다\n'
                        '• 다양한 결제 수단은 구매 전환율을 향상시킵니다\n'
                        '• 빠른 CS 응답은 재구매율을 높입니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}