class BusinessHours {
  final String id;
  final String shopId;
  final int dayOfWeek; // 0: 일요일, 1: 월요일, ..., 6: 토요일
  final String? openTime;
  final String? closeTime;
  final bool isClosed;

  BusinessHours({
    required this.id,
    required this.shopId,
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
  });

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      isClosed: json['is_closed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'day_of_week': dayOfWeek,
      'open_time': openTime,
      'close_time': closeTime,
      'is_closed': isClosed,
    };
  }

  String get dayName {
    const days = ['일', '월', '화', '수', '목', '금', '토'];
    return days[dayOfWeek];
  }

  String get displayText {
    if (isClosed) {
      return '휴무';
    }
    if (openTime != null && closeTime != null) {
      return '$openTime - $closeTime';
    }
    return '정보 없음';
  }
}