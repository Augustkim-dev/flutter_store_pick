enum EventType {
  sale('할인'),
  newProduct('신상품'),
  special('특별이벤트'),
  opening('오픈이벤트'),
  season('시즌이벤트');
  
  final String displayName;
  const EventType(this.displayName);
  
  static EventType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sale':
        return EventType.sale;
      case 'new_product':
        return EventType.newProduct;
      case 'special':
        return EventType.special;
      case 'opening':
        return EventType.opening;
      case 'season':
        return EventType.season;
      default:
        return EventType.special;
    }
  }
  
  String toDbString() {
    switch (this) {
      case EventType.sale:
        return 'sale';
      case EventType.newProduct:
        return 'new_product';
      case EventType.special:
        return 'special';
      case EventType.opening:
        return 'opening';
      case EventType.season:
        return 'season';
    }
  }
}

class Event {
  final String id;
  final String shopId;
  final String title;
  final String description;
  final EventType eventType;
  final String? imageUrl;
  final String? bannerUrl;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isFeatured;
  final String? discountRate;
  final String? promoCode;
  final String? targetProducts;
  final String? terms;
  final int? priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields from view
  final String? shopName;
  final String? shopImageUrl;
  final String? shopType;

  Event({
    required this.id,
    required this.shopId,
    required this.title,
    required this.description,
    required this.eventType,
    this.imageUrl,
    this.bannerUrl,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.isFeatured = false,
    this.discountRate,
    this.promoCode,
    this.targetProducts,
    this.terms,
    this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.shopName,
    this.shopImageUrl,
    this.shopType,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      eventType: EventType.fromString(json['event_type'] as String? ?? 'special'),
      imageUrl: json['image_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      discountRate: json['discount_rate'] as String?,
      promoCode: json['promo_code'] as String?,
      targetProducts: json['target_products'] as String?,
      terms: json['terms'] as String?,
      priority: json['priority'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      shopName: json['shop_name'] as String?,
      shopImageUrl: json['shop_image_url'] as String?,
      shopType: json['shop_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'title': title,
      'description': description,
      'event_type': eventType.toDbString(),
      'image_url': imageUrl,
      'banner_url': bannerUrl,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'is_featured': isFeatured,
      'discount_rate': discountRate,
      'promo_code': promoCode,
      'target_products': targetProducts,
      'terms': terms,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'shop_id': shopId,
      'title': title,
      'description': description,
      'event_type': eventType.toDbString(),
      'image_url': imageUrl,
      'banner_url': bannerUrl,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_active': isActive,
      'is_featured': isFeatured,
      'discount_rate': discountRate,
      'promo_code': promoCode,
      'target_products': targetProducts,
      'terms': terms,
      'priority': priority,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'description': description,
      'event_type': eventType.toDbString(),
      'image_url': imageUrl,
      'banner_url': bannerUrl,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_active': isActive,
      'is_featured': isFeatured,
      'discount_rate': discountRate,
      'promo_code': promoCode,
      'target_products': targetProducts,
      'terms': terms,
      'priority': priority,
    };
  }

  Event copyWith({
    String? id,
    String? shopId,
    String? title,
    String? description,
    EventType? eventType,
    String? imageUrl,
    String? bannerUrl,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isFeatured,
    String? discountRate,
    String? promoCode,
    String? targetProducts,
    String? terms,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? shopName,
    String? shopImageUrl,
    String? shopType,
  }) {
    return Event(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      discountRate: discountRate ?? this.discountRate,
      promoCode: promoCode ?? this.promoCode,
      targetProducts: targetProducts ?? this.targetProducts,
      terms: terms ?? this.terms,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shopName: shopName ?? this.shopName,
      shopImageUrl: shopImageUrl ?? this.shopImageUrl,
      shopType: shopType ?? this.shopType,
    );
  }

  bool get isOngoing {
    if (!isActive) return false;
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isUpcoming {
    if (!isActive) return false;
    final now = DateTime.now();
    return now.isBefore(startDate);
  }

  bool get isExpired {
    final now = DateTime.now();
    return now.isAfter(endDate);
  }

  String get statusText {
    if (!isActive) return '비활성';
    if (isExpired) return '종료';
    if (isUpcoming) return '예정';
    if (isOngoing) return '진행중';
    return '알 수 없음';
  }

  String get periodText {
    final fromText = '${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')}';
    final untilText = '${endDate.year}.${endDate.month.toString().padLeft(2, '0')}.${endDate.day.toString().padLeft(2, '0')}';
    return '$fromText ~ $untilText';
  }

  int get remainingDays {
    if (isExpired) return 0;
    final now = DateTime.now();
    if (isUpcoming) {
      return startDate.difference(now).inDays;
    }
    return endDate.difference(now).inDays;
  }

  String get remainingTimeText {
    final days = remainingDays;
    if (isExpired) return '종료됨';
    if (isUpcoming) return '$days일 후 시작';
    if (days == 0) return '오늘 마감';
    return '$days일 남음';
  }
}