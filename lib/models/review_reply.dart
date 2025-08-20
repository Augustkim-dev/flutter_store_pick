class ReviewReply {
  final String id;
  final String reviewId;
  final String shopId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewReply({
    required this.id,
    required this.reviewId,
    required this.shopId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewReply.fromJson(Map<String, dynamic> json) {
    return ReviewReply(
      id: json['id'] as String,
      reviewId: json['review_id'] as String,
      shopId: json['shop_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'review_id': reviewId,
      'shop_id': shopId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // For creating new replies
  Map<String, dynamic> toInsertJson() {
    return {
      'review_id': reviewId,
      'shop_id': shopId,
      'content': content,
    };
  }

  // For updating existing replies
  Map<String, dynamic> toUpdateJson() {
    return {
      'content': content,
    };
  }

  ReviewReply copyWith({
    String? id,
    String? reviewId,
    String? shopId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewReply(
      id: id ?? this.id,
      reviewId: reviewId ?? this.reviewId,
      shopId: shopId ?? this.shopId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get formatted date for display
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '방금 전';
        }
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else {
      return '${(difference.inDays / 365).floor()}년 전';
    }
  }

  // Check if reply was edited
  bool get wasEdited {
    return updatedAt.isAfter(createdAt.add(const Duration(seconds: 1)));
  }
}