class ShippingRegion {
  final String id;
  final String shopId;
  final String regionName;  // 서울, 경기, 제주 등
  final int shippingFee;  // 배송비
  final int? estimatedDays;  // 예상 배송일
  final DateTime createdAt;

  ShippingRegion({
    required this.id,
    required this.shopId,
    required this.regionName,
    required this.shippingFee,
    this.estimatedDays = 2,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ShippingRegion.fromJson(Map<String, dynamic> json) {
    return ShippingRegion(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      regionName: json['region_name'] as String,
      shippingFee: json['shipping_fee'] as int,
      estimatedDays: json['estimated_days'] as int? ?? 2,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'region_name': regionName,
      'shipping_fee': shippingFee,
      'estimated_days': estimatedDays,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  // 기본 지역 목록
  static List<String> get defaultRegions => [
    '서울',
    '경기',
    '인천',
    '대전',
    '세종',
    '충북',
    '충남',
    '대구',
    '경북',
    '부산',
    '울산',
    '경남',
    '광주',
    '전북',
    '전남',
    '강원',
    '제주',
  ];
  
  // 배송비 포맷
  String get formattedFee => '${shippingFee.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  )}원';
  
  // 배송 정보 텍스트
  String get deliveryInfo => estimatedDays != null 
    ? '$regionName ($estimatedDays일 소요)'
    : regionName;
}