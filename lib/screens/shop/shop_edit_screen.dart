import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';

class ShopEditScreen extends StatefulWidget {
  final Shop shop;

  const ShopEditScreen({super.key, required this.shop});

  @override
  State<ShopEditScreen> createState() => _ShopEditScreenState();
}

class _ShopEditScreenState extends State<ShopEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ShopService _shopService = ShopService();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _businessHoursController;
  late TextEditingController _shippingFeeController;
  late TextEditingController _freeShippingMinController;
  late TextEditingController _deliveryInfoController;
  
  late ShopType _selectedType;
  bool _parkingAvailable = false;
  bool _fittingAvailable = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _shopService.setSupabaseMode(true);
    _initControllers();
  }

  void _initControllers() {
    final shop = widget.shop;
    _nameController = TextEditingController(text: shop.name);
    _descriptionController = TextEditingController(text: shop.description);
    _phoneController = TextEditingController(text: shop.phone ?? '');
    _addressController = TextEditingController(text: shop.address ?? '');
    _websiteController = TextEditingController(text: shop.websiteUrl ?? '');
    _businessHoursController = TextEditingController(text: shop.businessHours ?? '');
    _shippingFeeController = TextEditingController(text: shop.shippingFee?.toString() ?? '');
    _freeShippingMinController = TextEditingController(text: shop.freeShippingMin?.toString() ?? '');
    _deliveryInfoController = TextEditingController(text: shop.deliveryInfo ?? '');
    
    _selectedType = shop.shopType;
    _parkingAvailable = shop.parkingAvailable ?? false;
    _fittingAvailable = shop.fittingAvailable ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _businessHoursController.dispose();
    _shippingFeeController.dispose();
    _freeShippingMinController.dispose();
    _deliveryInfoController.dispose();
    super.dispose();
  }

  Future<void> _saveShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedShop = Shop(
        id: widget.shop.id,
        name: _nameController.text,
        description: _descriptionController.text,
        shopType: _selectedType,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        websiteUrl: _websiteController.text.isNotEmpty ? _websiteController.text : null,
        businessHours: _businessHoursController.text.isNotEmpty ? _businessHoursController.text : null,
        shippingFee: _shippingFeeController.text.isNotEmpty 
            ? int.tryParse(_shippingFeeController.text) 
            : null,
        freeShippingMin: _freeShippingMinController.text.isNotEmpty 
            ? int.tryParse(_freeShippingMinController.text) 
            : null,
        deliveryInfo: _deliveryInfoController.text.isNotEmpty ? _deliveryInfoController.text : null,
        parkingAvailable: _parkingAvailable,
        fittingAvailable: _fittingAvailable,
        // 기존 값 유지
        brands: widget.shop.brands,
        rating: widget.shop.rating,
        reviewCount: widget.shop.reviewCount,
        imageUrl: widget.shop.imageUrl,
        ownerId: widget.shop.ownerId,
        latitude: widget.shop.latitude,
        longitude: widget.shop.longitude,
        categories: widget.shop.categories,
        isVerified: widget.shop.isVerified,
        createdAt: widget.shop.createdAt,
      );

      final success = await _shopService.updateShop(updatedShop);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상점 정보가 업데이트되었습니다')),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('업데이트 실패');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
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
        title: const Text('상점 정보 수정'),
        backgroundColor: AppColors.primaryPink,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveShop,
              child: const Text(
                '저장',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildShopTypeSection(),
            const SizedBox(height: 24),
            if (_selectedType != ShopType.online) _buildOfflineSection(),
            if (_selectedType != ShopType.offline) _buildOnlineSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기본 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '상점명',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '상점명을 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '상점 설명',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '상점 설명을 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '전화번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상점 유형',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
              selected: {_selectedType},
              onSelectionChanged: (Set<ShopType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오프라인 매장 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '주소',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessHoursController,
              decoration: const InputDecoration(
                labelText: '영업시간',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
                hintText: '예: 평일 10:00-20:00, 주말 10:00-18:00',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('주차 가능'),
              value: _parkingAvailable,
              onChanged: (value) {
                setState(() {
                  _parkingAvailable = value;
                });
              },
              secondary: const Icon(Icons.local_parking),
            ),
            SwitchListTile(
              title: const Text('시착 가능'),
              value: _fittingAvailable,
              onChanged: (value) {
                setState(() {
                  _fittingAvailable = value;
                });
              },
              secondary: const Icon(Icons.checkroom),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '온라인 쇼핑몰 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: '웹사이트 URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
                hintText: 'https://example.com',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shippingFeeController,
              decoration: const InputDecoration(
                labelText: '기본 배송비',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping),
                suffixText: '원',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _freeShippingMinController,
              decoration: const InputDecoration(
                labelText: '무료배송 최소금액',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.card_giftcard),
                suffixText: '원',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deliveryInfoController,
              decoration: const InputDecoration(
                labelText: '배송 정보',
                border: OutlineInputBorder(),
                hintText: '예: 평균 2-3일 소요',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}