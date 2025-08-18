class Review {
  final String id;
  final String userId;
  final String shopId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 조인된 사용자 정보
  final String? userName;
  final String? userAvatar;

  Review({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatar,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'],
      shopId: json['shop_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userName: json['user_name'],
      userAvatar: json['user_avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'shop_id': shopId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Review copyWith({
    String? id,
    String? userId,
    String? shopId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatar,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shopId: shopId ?? this.shopId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }
}

class ShopRating {
  final String shopId;
  final int reviewCount;
  final double averageRating;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  ShopRating({
    required this.shopId,
    required this.reviewCount,
    required this.averageRating,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
  });

  factory ShopRating.fromJson(Map<String, dynamic> json) {
    return ShopRating(
      shopId: json['shop_id'],
      reviewCount: json['review_count'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      fiveStarCount: json['five_star_count'] ?? 0,
      fourStarCount: json['four_star_count'] ?? 0,
      threeStarCount: json['three_star_count'] ?? 0,
      twoStarCount: json['two_star_count'] ?? 0,
      oneStarCount: json['one_star_count'] ?? 0,
    );
  }

  List<int> get starCounts => [
    oneStarCount,
    twoStarCount,
    threeStarCount,
    fourStarCount,
    fiveStarCount,
  ];

  double getStarPercentage(int stars) {
    if (reviewCount == 0) return 0;
    switch (stars) {
      case 5:
        return fiveStarCount / reviewCount;
      case 4:
        return fourStarCount / reviewCount;
      case 3:
        return threeStarCount / reviewCount;
      case 2:
        return twoStarCount / reviewCount;
      case 1:
        return oneStarCount / reviewCount;
      default:
        return 0;
    }
  }
}