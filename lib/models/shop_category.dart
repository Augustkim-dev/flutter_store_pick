class ShopCategory {
  final String id;
  final String shopId;
  final String categoryName;  // 토슈즈, 레오타드, 타이즈 등
  final bool isSpecialized;  // 전문 카테고리 여부
  final DateTime createdAt;

  ShopCategory({
    required this.id,
    required this.shopId,
    required this.categoryName,
    this.isSpecialized = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ShopCategory.fromJson(Map<String, dynamic> json) {
    return ShopCategory(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      categoryName: json['category_name'] as String,
      isSpecialized: json['is_specialized'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'category_name': categoryName,
      'is_specialized': isSpecialized,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  // 기본 발레 카테고리 목록
  static List<String> get defaultCategories => [
    '토슈즈',
    '레오타드',
    '타이즈',
    '스커트',
    '레그워머',
    '발레슈즈',
    '워밍업',
    '가방',
    '액세서리',
    '연습복',
    '공연의상',
    '기타',
  ];
}