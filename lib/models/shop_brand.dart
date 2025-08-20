class ShopBrand {
  final String id;
  final String shopId;
  final String brandId;
  final bool isMain;  // 주력 브랜드 여부
  final String? stockStatus;  // in_stock, low_stock, out_of_stock
  final DateTime createdAt;

  ShopBrand({
    required this.id,
    required this.shopId,
    required this.brandId,
    this.isMain = false,
    this.stockStatus = 'in_stock',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ShopBrand.fromJson(Map<String, dynamic> json) {
    return ShopBrand(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      brandId: json['brand_id'] as String,
      isMain: json['is_main'] as bool? ?? false,
      stockStatus: json['stock_status'] as String? ?? 'in_stock',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'brand_id': brandId,
      'is_main': isMain,
      'stock_status': stockStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  // 재고 상태 한글 표시
  String get stockStatusText {
    switch (stockStatus) {
      case 'in_stock':
        return '재고 있음';
      case 'low_stock':
        return '재고 부족';
      case 'out_of_stock':
        return '품절';
      default:
        return '알 수 없음';
    }
  }
}