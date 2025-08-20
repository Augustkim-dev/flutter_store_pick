class Announcement {
  final String id;
  final String shopId;
  final String title;
  final String content;
  final bool isPinned;
  final bool isActive;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields from view
  final String? shopName;
  final String? shopOwnerId;

  Announcement({
    required this.id,
    required this.shopId,
    required this.title,
    required this.content,
    this.isPinned = false,
    this.isActive = true,
    this.validFrom,
    this.validUntil,
    required this.createdAt,
    required this.updatedAt,
    this.shopName,
    this.shopOwnerId,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isPinned: json['is_pinned'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      validFrom: json['valid_from'] != null 
        ? DateTime.parse(json['valid_from'] as String)
        : null,
      validUntil: json['valid_until'] != null
        ? DateTime.parse(json['valid_until'] as String)
        : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      shopName: json['shop_name'] as String?,
      shopOwnerId: json['shop_owner_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'title': title,
      'content': content,
      'is_pinned': isPinned,
      'is_active': isActive,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // For creating new announcements
  Map<String, dynamic> toInsertJson() {
    return {
      'shop_id': shopId,
      'title': title,
      'content': content,
      'is_pinned': isPinned,
      'is_active': isActive,
      'valid_from': validFrom?.toIso8601String().split('T')[0], // Date only
      'valid_until': validUntil?.toIso8601String().split('T')[0], // Date only
    };
  }

  // For updating existing announcements
  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'content': content,
      'is_pinned': isPinned,
      'is_active': isActive,
      'valid_from': validFrom?.toIso8601String().split('T')[0], // Date only
      'valid_until': validUntil?.toIso8601String().split('T')[0], // Date only
    };
  }

  Announcement copyWith({
    String? id,
    String? shopId,
    String? title,
    String? content,
    bool? isPinned,
    bool? isActive,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? shopName,
    String? shopOwnerId,
  }) {
    return Announcement(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      isActive: isActive ?? this.isActive,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shopName: shopName ?? this.shopName,
      shopOwnerId: shopOwnerId ?? this.shopOwnerId,
    );
  }

  // Check if announcement is currently valid
  bool get isValid {
    if (!isActive) return false;
    
    final now = DateTime.now();
    
    if (validFrom != null && now.isBefore(validFrom!)) {
      return false;
    }
    
    if (validUntil != null && now.isAfter(validUntil!)) {
      return false;
    }
    
    return true;
  }

  // Get status text
  String get statusText {
    if (!isActive) return '비활성';
    if (!isValid) {
      final now = DateTime.now();
      if (validFrom != null && now.isBefore(validFrom!)) {
        return '예정';
      }
      if (validUntil != null && now.isAfter(validUntil!)) {
        return '종료';
      }
    }
    return '활성';
  }

  // Format dates for display
  String get validPeriodText {
    if (validFrom == null && validUntil == null) {
      return '상시';
    }
    
    final fromText = validFrom != null 
      ? '${validFrom!.year}.${validFrom!.month.toString().padLeft(2, '0')}.${validFrom!.day.toString().padLeft(2, '0')}'
      : '';
    final untilText = validUntil != null
      ? '${validUntil!.year}.${validUntil!.month.toString().padLeft(2, '0')}.${validUntil!.day.toString().padLeft(2, '0')}'
      : '';
    
    if (validFrom != null && validUntil != null) {
      return '$fromText ~ $untilText';
    } else if (validFrom != null) {
      return '$fromText부터';
    } else {
      return '$untilText까지';
    }
  }
}