enum ShopType {
  offline('오프라인'),
  online('온라인'),
  hybrid('온/오프라인');
  
  final String displayName;
  const ShopType(this.displayName);
}

class Shop {
  final String id;
  final String name;
  final ShopType shopType;
  final String description;
  final List<String> brands;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  
  // 오프라인 상점 정보
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? businessHours;
  final bool? parkingAvailable;
  final bool? fittingAvailable;
  
  // 온라인 상점 정보
  final String? websiteUrl;
  final int? shippingFee;
  final int? freeShippingMin;
  final String? deliveryInfo;
  
  // 공통 추가 정보
  final List<String> categories;
  final bool isVerified;
  final DateTime createdAt;

  Shop({
    required this.id,
    required this.name,
    required this.shopType,
    required this.description,
    required this.brands,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.businessHours,
    this.parkingAvailable,
    this.fittingAvailable,
    this.websiteUrl,
    this.shippingFee,
    this.freeShippingMin,
    this.deliveryInfo,
    required this.categories,
    this.isVerified = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // 오프라인 상점인지 확인
  bool get isOffline => shopType == ShopType.offline || shopType == ShopType.hybrid;
  
  // 온라인 상점인지 확인
  bool get isOnline => shopType == ShopType.online || shopType == ShopType.hybrid;
  
  // 무료배송 여부
  bool get hasFreeShipping => 
    isOnline && freeShippingMin != null && freeShippingMin! > 0;
  
  // 주요 브랜드 (최대 3개)
  List<String> get mainBrands => 
    brands.take(3).toList();
  
  // 평점 텍스트
  String get ratingText => rating.toStringAsFixed(1);
}