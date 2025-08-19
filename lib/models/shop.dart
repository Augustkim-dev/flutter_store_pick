enum ShopType {
  offline('오프라인'),
  online('온라인'),
  hybrid('온/오프라인');
  
  final String displayName;
  const ShopType(this.displayName);
  
  static ShopType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'offline':
        return ShopType.offline;
      case 'online':
        return ShopType.online;
      case 'hybrid':
        return ShopType.hybrid;
      default:
        return ShopType.offline;
    }
  }
  
  String toDbString() {
    switch (this) {
      case ShopType.offline:
        return 'offline';
      case ShopType.online:
        return 'online';
      case ShopType.hybrid:
        return 'hybrid';
    }
  }
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
  final String? ownerId;  // 상점 소유자 ID
  
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
    this.ownerId,
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
  
  // Supabase JSON 변환
  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      name: json['name'] as String,
      shopType: ShopType.fromString(json['shop_type'] as String),
      description: json['description'] as String? ?? '',
      brands: (json['brands'] as List<dynamic>?)?.cast<String>() ?? [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      ownerId: json['owner_id'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      businessHours: json['business_hours'] as String?,
      parkingAvailable: json['parking_available'] as bool?,
      fittingAvailable: json['fitting_available'] as bool?,
      websiteUrl: json['website_url'] as String?,
      shippingFee: json['shipping_fee'] as int?,
      freeShippingMin: json['free_shipping_min'] as int?,
      deliveryInfo: json['delivery_info'] as String?,
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shop_type': shopType.toDbString(),
      'description': description,
      'brands': brands,
      'rating': rating,
      'review_count': reviewCount,
      'image_url': imageUrl,
      'owner_id': ownerId,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'business_hours': businessHours,
      'parking_available': parkingAvailable,
      'fitting_available': fittingAvailable,
      'website_url': websiteUrl,
      'shipping_fee': shippingFee,
      'free_shipping_min': freeShippingMin,
      'delivery_info': deliveryInfo,
      'categories': categories,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}