import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/shop.dart';
import '../../../theme/app_colors.dart';

class BasicInfoTab extends StatefulWidget {
  final Shop shop;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController kakaoIdController;
  final TextEditingController businessNumberController;
  final ValueChanged<ShopType> onShopTypeChanged;
  final ShopType selectedType;
  final bool pickupService;
  final bool onlineToOffline;
  final ValueChanged<bool> onPickupServiceChanged;
  final ValueChanged<bool> onOnlineToOfflineChanged;

  const BasicInfoTab({
    super.key,
    required this.shop,
    required this.nameController,
    required this.descriptionController,
    required this.phoneController,
    required this.emailController,
    required this.kakaoIdController,
    required this.businessNumberController,
    required this.onShopTypeChanged,
    required this.selectedType,
    this.pickupService = false,
    this.onlineToOffline = false,
    required this.onPickupServiceChanged,
    required this.onOnlineToOfflineChanged,
  });

  @override
  State<BasicInfoTab> createState() => _BasicInfoTabState();
}

class _BasicInfoTabState extends State<BasicInfoTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상점 유형 선택
          _buildSectionTitle('상점 유형'),
          const SizedBox(height: 12),
          SegmentedButton<ShopType>(
            segments: const [
              ButtonSegment(
                value: ShopType.offline,
                label: Text('오프라인'),
                icon: Icon(Icons.store),
              ),
              ButtonSegment(
                value: ShopType.online,
                label: Text('온라인'),
                icon: Icon(Icons.language),
              ),
              ButtonSegment(
                value: ShopType.hybrid,
                label: Text('온/오프라인'),
                icon: Icon(Icons.merge_type),
              ),
            ],
            selected: {widget.selectedType},
            onSelectionChanged: (Set<ShopType> newSelection) {
              widget.onShopTypeChanged(newSelection.first);
            },
          ),
          const SizedBox(height: 24),

          // 기본 정보
          _buildSectionTitle('기본 정보', isRequired: true),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.nameController,
            decoration: const InputDecoration(
              labelText: '상점명 *',
              hintText: '상점 이름을 입력하세요',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.store),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '상점명은 필수입니다';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.descriptionController,
            decoration: const InputDecoration(
              labelText: '상점 소개 *',
              hintText: '상점을 소개하는 문구를 입력하세요',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '상점 소개는 필수입니다';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // 사업자 정보
          _buildSectionTitle('사업자 정보'),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.businessNumberController,
            decoration: const InputDecoration(
              labelText: '사업자 등록번호',
              hintText: '000-00-00000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
              helperText: '하이픈(-)을 포함하여 입력하세요',
            ),
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
              LengthLimitingTextInputFormatter(12),
            ],
          ),
          const SizedBox(height: 24),

          // 연락처 정보
          _buildSectionTitle('연락처 정보'),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.phoneController,
            decoration: const InputDecoration(
              labelText: '전화번호',
              hintText: '02-1234-5678',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.emailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              hintText: 'shop@example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return '올바른 이메일 형식이 아닙니다';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.kakaoIdController,
            decoration: const InputDecoration(
              labelText: '카카오톡 ID',
              hintText: '카카오톡 아이디 또는 채널명',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.chat),
              helperText: '고객 문의를 받을 카카오톡 ID를 입력하세요',
            ),
          ),
          const SizedBox(height: 24),

          // 복합 상점 옵션 (온/오프라인 상점만)
          if (widget.selectedType == ShopType.hybrid) ...[
            _buildSectionTitle('복합 상점 옵션'),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('매장 픽업 서비스'),
                    subtitle: const Text('온라인 주문 후 매장에서 수령 가능'),
                    value: widget.pickupService,
                    onChanged: widget.onPickupServiceChanged,
                    secondary: const Icon(Icons.shopping_bag),
                    activeColor: AppColors.primaryPink,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('O2O 서비스'),
                    subtitle: const Text('온라인 주문 → 오프라인 수령/체험'),
                    value: widget.onlineToOffline,
                    onChanged: widget.onOnlineToOfflineChanged,
                    secondary: const Icon(Icons.sync_alt),
                    activeColor: AppColors.primaryPink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    size: 20,
                    color: Colors.purple.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '복합 상점의 이점',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• 온라인 고객과 오프라인 고객 모두 확보\n'
                          '• 픽업 서비스로 배송비 절감 효과\n'
                          '• 매장 방문 유도로 추가 매출 기회',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 도움말
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryPink.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.primaryPink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '입력 도움말',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• * 표시는 필수 입력 항목입니다\n'
                        '• 사업자 등록번호는 인증에 사용됩니다\n'
                        '• 연락처 정보는 고객에게 표시됩니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryPink.withValues(alpha: 0.8),
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

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}