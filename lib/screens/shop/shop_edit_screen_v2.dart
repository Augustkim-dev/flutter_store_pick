import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../models/brand.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import 'shop_edit_tabs/basic_info_tab.dart';
import 'shop_edit_tabs/offline_info_tab.dart';
import 'shop_edit_tabs/online_info_tab.dart';
import 'shop_edit_tabs/brands_categories_tab.dart';
import 'shop_edit_tabs/images_tab.dart';

class ShopEditScreenV2 extends StatefulWidget {
  final Shop shop;

  const ShopEditScreenV2({super.key, required this.shop});

  @override
  State<ShopEditScreenV2> createState() => _ShopEditScreenV2State();
}

class _ShopEditScreenV2State extends State<ShopEditScreenV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final ShopService _shopService = ShopService();
  
  // 기본 정보 컨트롤러
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _kakaoIdController;
  late TextEditingController _businessNumberController;
  
  // 오프라인 정보 컨트롤러
  late TextEditingController _addressController;
  late TextEditingController _detailedLocationController;
  late TextEditingController _businessHoursController;
  late TextEditingController _lunchBreakStartController;
  late TextEditingController _lunchBreakEndController;
  late TextEditingController _directionsPublicController;
  late TextEditingController _directionsWalkingController;
  late TextEditingController _parkingInfoController;
  
  // 온라인 정보 컨트롤러
  late TextEditingController _websiteController;
  late TextEditingController _shippingFeeController;
  late TextEditingController _freeShippingMinController;
  late TextEditingController _deliveryInfoController;
  late TextEditingController _csHoursController;
  late TextEditingController _csPhoneController;
  late TextEditingController _csKakaoController;
  late TextEditingController _csEmailController;
  late TextEditingController _exchangePolicyController;
  late TextEditingController _refundPolicyController;
  late TextEditingController _returnShippingFeeController;
  
  // 상태 변수
  late ShopType _selectedType;
  bool _parkingAvailable = false;
  bool _fittingAvailable = false;
  bool _wheelchairAccessible = false;
  bool _kidsFriendly = false;
  bool _mobileWebSupport = true;
  bool _sameDayDelivery = false;
  bool _pickupService = false;
  bool _onlineToOffline = false;
  List<String> _paymentMethods = [];
  
  // 브랜드/카테고리
  List<Brand> _selectedBrands = [];
  List<String> _selectedCategories = [];
  
  // 이미지
  String? _mainImageUrl;
  List<String> _galleryImageUrls = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _shopService.setSupabaseMode(true);
    _initControllers();
    _loadExistingData();
  }

  void _initControllers() {
    final shop = widget.shop;
    
    // 기본 정보
    _nameController = TextEditingController(text: shop.name);
    _descriptionController = TextEditingController(text: shop.description);
    _phoneController = TextEditingController(text: shop.phone ?? '');
    _emailController = TextEditingController(text: shop.email ?? '');
    _kakaoIdController = TextEditingController(text: shop.kakaoId ?? '');
    _businessNumberController = TextEditingController(text: shop.businessNumber ?? '');
    
    // 오프라인 정보
    _addressController = TextEditingController(text: shop.address ?? '');
    _detailedLocationController = TextEditingController(text: shop.detailedLocation ?? '');
    _businessHoursController = TextEditingController(text: shop.businessHours ?? '');
    _lunchBreakStartController = TextEditingController(text: shop.lunchBreakStart ?? '');
    _lunchBreakEndController = TextEditingController(text: shop.lunchBreakEnd ?? '');
    _directionsPublicController = TextEditingController(text: shop.directionsPublic ?? '');
    _directionsWalkingController = TextEditingController(text: shop.directionsWalking ?? '');
    _parkingInfoController = TextEditingController(text: shop.parkingInfo ?? '');
    
    // 온라인 정보
    _websiteController = TextEditingController(text: shop.websiteUrl ?? '');
    _shippingFeeController = TextEditingController(text: shop.shippingFee?.toString() ?? '');
    _freeShippingMinController = TextEditingController(text: shop.freeShippingMin?.toString() ?? '');
    _deliveryInfoController = TextEditingController(text: shop.deliveryInfo ?? '');
    _csHoursController = TextEditingController(text: shop.csHours ?? '');
    _csPhoneController = TextEditingController(text: shop.csPhone ?? '');
    _csKakaoController = TextEditingController(text: shop.csKakao ?? '');
    _csEmailController = TextEditingController(text: shop.csEmail ?? '');
    _exchangePolicyController = TextEditingController(text: shop.exchangePolicy ?? '');
    _refundPolicyController = TextEditingController(text: shop.refundPolicy ?? '');
    _returnShippingFeeController = TextEditingController(text: shop.returnShippingFee?.toString() ?? '');
    
    // 상태 초기화
    _selectedType = shop.shopType;
    _parkingAvailable = shop.parkingAvailable ?? false;
    _fittingAvailable = shop.fittingAvailable ?? false;
    _wheelchairAccessible = shop.wheelchairAccessible ?? false;
    _kidsFriendly = shop.kidsFriendly ?? false;
    _mobileWebSupport = shop.mobileWebSupport ?? true;
    _sameDayDelivery = shop.sameDayDelivery ?? false;
    _pickupService = shop.pickupService ?? false;
    _onlineToOffline = shop.onlineToOffline ?? false;
    _paymentMethods = shop.paymentMethods ?? [];
    
    // 이미지
    _mainImageUrl = shop.imageUrl;
    _galleryImageUrls = shop.imageUrls ?? [];
    
    // 브랜드/카테고리
    _selectedCategories = shop.categories;
  }

  Future<void> _loadExistingData() async {
    // TODO: 브랜드, 카테고리 등 추가 데이터 로드
  }

  @override
  void dispose() {
    _tabController.dispose();
    // 모든 컨트롤러 dispose
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _kakaoIdController.dispose();
    _businessNumberController.dispose();
    _addressController.dispose();
    _detailedLocationController.dispose();
    _businessHoursController.dispose();
    _lunchBreakStartController.dispose();
    _lunchBreakEndController.dispose();
    _directionsPublicController.dispose();
    _directionsWalkingController.dispose();
    _parkingInfoController.dispose();
    _websiteController.dispose();
    _shippingFeeController.dispose();
    _freeShippingMinController.dispose();
    _deliveryInfoController.dispose();
    _csHoursController.dispose();
    _csPhoneController.dispose();
    _csKakaoController.dispose();
    _csEmailController.dispose();
    _exchangePolicyController.dispose();
    _refundPolicyController.dispose();
    _returnShippingFeeController.dispose();
    super.dispose();
  }

  Future<void> _saveShop() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 항목을 모두 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedShop = Shop(
        id: widget.shop.id,
        name: _nameController.text,
        description: _descriptionController.text,
        shopType: _selectedType,
        brands: widget.shop.brands, // TODO: 브랜드 업데이트
        rating: widget.shop.rating,
        reviewCount: widget.shop.reviewCount,
        imageUrl: _mainImageUrl ?? widget.shop.imageUrl,
        ownerId: widget.shop.ownerId,
        // 공통 정보
        businessNumber: _businessNumberController.text.isNotEmpty ? _businessNumberController.text : null,
        imageUrls: _galleryImageUrls.isNotEmpty ? _galleryImageUrls : null,
        kakaoId: _kakaoIdController.text.isNotEmpty ? _kakaoIdController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        // 오프라인 정보
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        latitude: widget.shop.latitude,
        longitude: widget.shop.longitude,
        businessHours: _businessHoursController.text.isNotEmpty ? _businessHoursController.text : null,
        parkingAvailable: _parkingAvailable,
        fittingAvailable: _fittingAvailable,
        detailedLocation: _detailedLocationController.text.isNotEmpty ? _detailedLocationController.text : null,
        lunchBreakStart: _lunchBreakStartController.text.isNotEmpty ? _lunchBreakStartController.text : null,
        lunchBreakEnd: _lunchBreakEndController.text.isNotEmpty ? _lunchBreakEndController.text : null,
        wheelchairAccessible: _wheelchairAccessible,
        kidsFriendly: _kidsFriendly,
        directionsPublic: _directionsPublicController.text.isNotEmpty ? _directionsPublicController.text : null,
        directionsWalking: _directionsWalkingController.text.isNotEmpty ? _directionsWalkingController.text : null,
        parkingInfo: _parkingInfoController.text.isNotEmpty ? _parkingInfoController.text : null,
        // 온라인 정보
        websiteUrl: _websiteController.text.isNotEmpty ? _websiteController.text : null,
        shippingFee: _shippingFeeController.text.isNotEmpty 
            ? int.tryParse(_shippingFeeController.text) 
            : null,
        freeShippingMin: _freeShippingMinController.text.isNotEmpty 
            ? int.tryParse(_freeShippingMinController.text) 
            : null,
        deliveryInfo: _deliveryInfoController.text.isNotEmpty ? _deliveryInfoController.text : null,
        mobileWebSupport: _mobileWebSupport,
        sameDayDelivery: _sameDayDelivery,
        paymentMethods: _paymentMethods.isNotEmpty ? _paymentMethods : null,
        csHours: _csHoursController.text.isNotEmpty ? _csHoursController.text : null,
        csPhone: _csPhoneController.text.isNotEmpty ? _csPhoneController.text : null,
        csKakao: _csKakaoController.text.isNotEmpty ? _csKakaoController.text : null,
        csEmail: _csEmailController.text.isNotEmpty ? _csEmailController.text : null,
        exchangePolicy: _exchangePolicyController.text.isNotEmpty ? _exchangePolicyController.text : null,
        refundPolicy: _refundPolicyController.text.isNotEmpty ? _refundPolicyController.text : null,
        returnShippingFee: _returnShippingFeeController.text.isNotEmpty 
            ? int.tryParse(_returnShippingFeeController.text) 
            : null,
        // 복합 상점 정보
        pickupService: _pickupService,
        onlineToOffline: _onlineToOffline,
        // 기타
        categories: _selectedCategories,
        isVerified: widget.shop.isVerified,
        createdAt: widget.shop.createdAt,
      );

      final success = await _shopService.updateShop(updatedShop);

      if (success) {
        // TODO: 브랜드, 카테고리, 배송지역 업데이트
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('상점 정보가 업데이트되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('업데이트 실패');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '기본정보'),
            Tab(text: '오프라인'),
            Tab(text: '온라인'),
            Tab(text: '브랜드/카테고리'),
            Tab(text: '이미지'),
          ],
        ),
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // 기본 정보 탭
            BasicInfoTab(
              shop: widget.shop,
              nameController: _nameController,
              descriptionController: _descriptionController,
              phoneController: _phoneController,
              emailController: _emailController,
              kakaoIdController: _kakaoIdController,
              businessNumberController: _businessNumberController,
              selectedType: _selectedType,
              onShopTypeChanged: (type) {
                setState(() {
                  _selectedType = type;
                });
              },
              pickupService: _pickupService,
              onlineToOffline: _onlineToOffline,
              onPickupServiceChanged: (value) => setState(() => _pickupService = value),
              onOnlineToOfflineChanged: (value) => setState(() => _onlineToOffline = value),
            ),
            
            // 오프라인 정보 탭
            OfflineInfoTab(
              shop: widget.shop,
              addressController: _addressController,
              detailedLocationController: _detailedLocationController,
              businessHoursController: _businessHoursController,
              lunchBreakStartController: _lunchBreakStartController,
              lunchBreakEndController: _lunchBreakEndController,
              directionsPublicController: _directionsPublicController,
              directionsWalkingController: _directionsWalkingController,
              parkingInfoController: _parkingInfoController,
              parkingAvailable: _parkingAvailable,
              fittingAvailable: _fittingAvailable,
              wheelchairAccessible: _wheelchairAccessible,
              kidsFriendly: _kidsFriendly,
              onParkingChanged: (value) => setState(() => _parkingAvailable = value),
              onFittingChanged: (value) => setState(() => _fittingAvailable = value),
              onWheelchairChanged: (value) => setState(() => _wheelchairAccessible = value),
              onKidsChanged: (value) => setState(() => _kidsFriendly = value),
            ),
            
            // 온라인 정보 탭
            OnlineInfoTab(
              shop: widget.shop,
              websiteController: _websiteController,
              shippingFeeController: _shippingFeeController,
              freeShippingMinController: _freeShippingMinController,
              deliveryInfoController: _deliveryInfoController,
              csHoursController: _csHoursController,
              csPhoneController: _csPhoneController,
              csKakaoController: _csKakaoController,
              csEmailController: _csEmailController,
              exchangePolicyController: _exchangePolicyController,
              refundPolicyController: _refundPolicyController,
              returnShippingFeeController: _returnShippingFeeController,
              mobileWebSupport: _mobileWebSupport,
              sameDayDelivery: _sameDayDelivery,
              paymentMethods: _paymentMethods,
              onMobileWebChanged: (value) => setState(() => _mobileWebSupport = value),
              onSameDayChanged: (value) => setState(() => _sameDayDelivery = value),
              onPaymentMethodsChanged: (methods) => setState(() => _paymentMethods = methods),
            ),
            
            // 브랜드/카테고리 탭
            BrandsCategoriesTab(
              shop: widget.shop,
              selectedBrands: _selectedBrands,
              selectedCategories: _selectedCategories,
              onBrandsChanged: (brands) => setState(() => _selectedBrands = brands),
              onCategoriesChanged: (categories) => setState(() => _selectedCategories = categories),
            ),
            
            // 이미지 탭
            ImagesTab(
              shop: widget.shop,
              mainImageUrl: _mainImageUrl,
              galleryImageUrls: _galleryImageUrls,
              onMainImageChanged: (url) => setState(() => _mainImageUrl = url),
              onGalleryImagesChanged: (urls) => setState(() => _galleryImageUrls = urls),
            ),
          ],
        ),
      ),
    );
  }
}