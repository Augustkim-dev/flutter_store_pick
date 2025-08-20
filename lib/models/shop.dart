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
  
  // 공통 정보
  final String? businessNumber;  // 사업자 번호
  final List<String>? imageUrls;  // 갤러리 이미지들
  final String? kakaoId;  // 카카오톡 ID
  final String? email;  // 이메일
  
  // 오프라인 상점 정보
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? businessHours;
  final bool? parkingAvailable;
  final bool? fittingAvailable;
  final String? detailedLocation;  // 상세 위치 (2층, 지하 등)
  final String? lunchBreakStart;  // 점심시간 시작
  final String? lunchBreakEnd;  // 점심시간 종료
  final bool? wheelchairAccessible;  // 휠체어 접근성
  final bool? kidsFriendly;  // 아동 동반 가능
  final String? directionsPublic;  // 대중교통 안내
  final String? directionsWalking;  // 도보 경로
  final String? parkingInfo;  // 주차 정보
  
  // 온라인 상점 정보
  final String? websiteUrl;
  final int? shippingFee;
  final int? freeShippingMin;
  final String? deliveryInfo;
  final bool? mobileWebSupport;  // 모바일 웹 지원
  final bool? sameDayDelivery;  // 당일배송 가능
  final List<String>? paymentMethods;  // 결제 수단
  final String? csHours;  // 고객센터 운영시간
  final String? csPhone;  // 고객센터 전화
  final String? csKakao;  // 고객센터 카카오톡
  final String? csEmail;  // 고객센터 이메일
  final String? exchangePolicy;  // 교환 정책
  final String? refundPolicy;  // 환불 정책
  final int? returnShippingFee;  // 반품 배송비
  
  // 복합 상점 정보
  final bool? pickupService;  // 픽업 서비스
  final bool? onlineToOffline;  // 온라인 주문 → 오프라인 수령
  
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
    // 공통 정보
    this.businessNumber,
    this.imageUrls,
    this.kakaoId,
    this.email,
    // 오프라인 정보
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.businessHours,
    this.parkingAvailable,
    this.fittingAvailable,
    this.detailedLocation,
    this.lunchBreakStart,
    this.lunchBreakEnd,
    this.wheelchairAccessible,
    this.kidsFriendly,
    this.directionsPublic,
    this.directionsWalking,
    this.parkingInfo,
    // 온라인 정보
    this.websiteUrl,
    this.shippingFee,
    this.freeShippingMin,
    this.deliveryInfo,
    this.mobileWebSupport,
    this.sameDayDelivery,
    this.paymentMethods,
    this.csHours,
    this.csPhone,
    this.csKakao,
    this.csEmail,
    this.exchangePolicy,
    this.refundPolicy,
    this.returnShippingFee,
    // 복합 상점 정보
    this.pickupService,
    this.onlineToOffline,
    // 기타
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
      // 공통 정보
      businessNumber: json['business_number'] as String?,
      imageUrls: (json['image_urls'] as List<dynamic>?)?.cast<String>(),
      kakaoId: json['kakao_id'] as String?,
      email: json['email'] as String?,
      // 오프라인 정보
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      businessHours: json['business_hours'] as String?,
      parkingAvailable: json['parking_available'] as bool?,
      fittingAvailable: json['fitting_available'] as bool?,
      detailedLocation: json['detailed_location'] as String?,
      lunchBreakStart: json['lunch_break_start'] as String?,
      lunchBreakEnd: json['lunch_break_end'] as String?,
      wheelchairAccessible: json['wheelchair_accessible'] as bool?,
      kidsFriendly: json['kids_friendly'] as bool?,
      directionsPublic: json['directions_public'] as String?,
      directionsWalking: json['directions_walking'] as String?,
      parkingInfo: json['parking_info'] as String?,
      // 온라인 정보
      websiteUrl: json['website_url'] as String?,
      shippingFee: json['shipping_fee'] as int?,
      freeShippingMin: json['free_shipping_min'] as int?,
      deliveryInfo: json['delivery_info'] as String?,
      mobileWebSupport: json['mobile_web_support'] as bool?,
      sameDayDelivery: json['same_day_delivery'] as bool?,
      paymentMethods: (json['payment_methods'] as List<dynamic>?)?.cast<String>(),
      csHours: json['cs_hours'] as String?,
      csPhone: json['cs_phone'] as String?,
      csKakao: json['cs_kakao'] as String?,
      csEmail: json['cs_email'] as String?,
      exchangePolicy: json['exchange_policy'] as String?,
      refundPolicy: json['refund_policy'] as String?,
      returnShippingFee: json['return_shipping_fee'] as int?,
      // 복합 상점 정보
      pickupService: json['pickup_service'] as bool?,
      onlineToOffline: json['online_to_offline'] as bool?,
      // 기타
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
      // 공통 정보
      'business_number': businessNumber,
      'image_urls': imageUrls,
      'kakao_id': kakaoId,
      'email': email,
      // 오프라인 정보
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'business_hours': businessHours,
      'parking_available': parkingAvailable,
      'fitting_available': fittingAvailable,
      'detailed_location': detailedLocation,
      'lunch_break_start': lunchBreakStart,
      'lunch_break_end': lunchBreakEnd,
      'wheelchair_accessible': wheelchairAccessible,
      'kids_friendly': kidsFriendly,
      'directions_public': directionsPublic,
      'directions_walking': directionsWalking,
      'parking_info': parkingInfo,
      // 온라인 정보
      'website_url': websiteUrl,
      'shipping_fee': shippingFee,
      'free_shipping_min': freeShippingMin,
      'delivery_info': deliveryInfo,
      'mobile_web_support': mobileWebSupport,
      'same_day_delivery': sameDayDelivery,
      'payment_methods': paymentMethods,
      'cs_hours': csHours,
      'cs_phone': csPhone,
      'cs_kakao': csKakao,
      'cs_email': csEmail,
      'exchange_policy': exchangePolicy,
      'refund_policy': refundPolicy,
      'return_shipping_fee': returnShippingFee,
      // 복합 상점 정보
      'pickup_service': pickupService,
      'online_to_offline': onlineToOffline,
      // 기타
      'categories': categories,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}