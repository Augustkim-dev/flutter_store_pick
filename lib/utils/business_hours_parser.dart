import '../utils/app_logger.dart';

class BusinessHoursParser {
  static const Map<String, int> weekdayMap = {
    '월': 1,
    '화': 2,
    '수': 3,
    '목': 4,
    '금': 5,
    '토': 6,
    '일': 7,
    '월요일': 1,
    '화요일': 2,
    '수요일': 3,
    '목요일': 4,
    '금요일': 5,
    '토요일': 6,
    '일요일': 7,
  };

  static bool isOpenNow(String? businessHours) {
    if (businessHours == null || businessHours.isEmpty) {
      AppLogger.d('BusinessHoursParser: businessHours is null or empty, defaulting to closed');
      return false;
    }

    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTimeInMinutes = currentHour * 60 + currentMinute;
    
    AppLogger.d('BusinessHoursParser: Checking if open at ${now.toString()}');
    AppLogger.d('BusinessHoursParser: businessHours = "$businessHours"');
    
    try {
      // 휴무일 체크
      if (businessHours.contains('휴무')) {
        final closedDays = _extractClosedDays(businessHours);
        if (closedDays.contains(currentWeekday)) {
          AppLogger.d('BusinessHoursParser: Closed today (휴무일)');
          return false;
        }
      }
      
      // 예약제 체크
      if (businessHours.contains('예약제')) {
        AppLogger.d('BusinessHoursParser: Reservation only, considering as open');
        return true;
      }
      
      // 매일 패턴 체크 (예: "매일 10:00-20:00")
      final dailyPattern = RegExp(r'매일\s*(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})');
      final dailyMatch = dailyPattern.firstMatch(businessHours);
      if (dailyMatch != null) {
        final openHour = int.parse(dailyMatch.group(1)!);
        final openMinute = int.parse(dailyMatch.group(2)!);
        final closeHour = int.parse(dailyMatch.group(3)!);
        final closeMinute = int.parse(dailyMatch.group(4)!);
        
        final openTime = openHour * 60 + openMinute;
        final closeTime = closeHour * 60 + closeMinute;
        
        final isOpen = currentTimeInMinutes >= openTime && currentTimeInMinutes < closeTime;
        AppLogger.d('BusinessHoursParser: Daily hours $openHour:$openMinute-$closeHour:$closeMinute, currently ${isOpen ? "OPEN" : "CLOSED"}');
        return isOpen;
      }
      
      // 평일/주말 패턴 체크
      final weekdayPattern = RegExp(r'평일\s*(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})');
      final weekendPattern = RegExp(r'주말\s*(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})');
      
      if (currentWeekday >= 1 && currentWeekday <= 5) {
        // 평일
        final weekdayMatch = weekdayPattern.firstMatch(businessHours);
        if (weekdayMatch != null) {
          final openHour = int.parse(weekdayMatch.group(1)!);
          final openMinute = int.parse(weekdayMatch.group(2)!);
          final closeHour = int.parse(weekdayMatch.group(3)!);
          final closeMinute = int.parse(weekdayMatch.group(4)!);
          
          final openTime = openHour * 60 + openMinute;
          final closeTime = closeHour * 60 + closeMinute;
          
          final isOpen = currentTimeInMinutes >= openTime && currentTimeInMinutes < closeTime;
          AppLogger.d('BusinessHoursParser: Weekday hours $openHour:$openMinute-$closeHour:$closeMinute, currently ${isOpen ? "OPEN" : "CLOSED"}');
          return isOpen;
        }
      } else {
        // 주말
        final weekendMatch = weekendPattern.firstMatch(businessHours);
        if (weekendMatch != null) {
          final openHour = int.parse(weekendMatch.group(1)!);
          final openMinute = int.parse(weekendMatch.group(2)!);
          final closeHour = int.parse(weekendMatch.group(3)!);
          final closeMinute = int.parse(weekendMatch.group(4)!);
          
          final openTime = openHour * 60 + openMinute;
          final closeTime = closeHour * 60 + closeMinute;
          
          final isOpen = currentTimeInMinutes >= openTime && currentTimeInMinutes < closeTime;
          AppLogger.d('BusinessHoursParser: Weekend hours $openHour:$openMinute-$closeHour:$closeMinute, currently ${isOpen ? "OPEN" : "CLOSED"}');
          return isOpen;
        }
      }
      
      // 요일 범위 패턴 체크 (예: "화-일 10:00-19:00")
      final rangePattern = RegExp(r'([월화수목금토일])-([월화수목금토일])\s*(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})');
      final rangeMatch = rangePattern.firstMatch(businessHours);
      if (rangeMatch != null) {
        final startDay = weekdayMap[rangeMatch.group(1)!]!;
        final endDay = weekdayMap[rangeMatch.group(2)!]!;
        
        bool isInRange = false;
        if (startDay <= endDay) {
          isInRange = currentWeekday >= startDay && currentWeekday <= endDay;
        } else {
          // 주를 넘어가는 경우 (예: 금-화)
          isInRange = currentWeekday >= startDay || currentWeekday <= endDay;
        }
        
        if (isInRange) {
          final openHour = int.parse(rangeMatch.group(3)!);
          final openMinute = int.parse(rangeMatch.group(4)!);
          final closeHour = int.parse(rangeMatch.group(5)!);
          final closeMinute = int.parse(rangeMatch.group(6)!);
          
          final openTime = openHour * 60 + openMinute;
          final closeTime = closeHour * 60 + closeMinute;
          
          final isOpen = currentTimeInMinutes >= openTime && currentTimeInMinutes < closeTime;
          AppLogger.d('BusinessHoursParser: Range ${rangeMatch.group(1)}-${rangeMatch.group(2)} hours $openHour:$openMinute-$closeHour:$closeMinute, currently ${isOpen ? "OPEN" : "CLOSED"}');
          return isOpen;
        } else {
          AppLogger.d('BusinessHoursParser: Not in operating day range');
          return false;
        }
      }
      
      // 특정 요일 패턴 체크 (예: "토요일 10:00-17:00")
      for (final entry in weekdayMap.entries) {
        if (businessHours.contains(entry.key)) {
          final pattern = RegExp('${entry.key}\\s*(\\d{1,2}):(\\d{2})-(\\d{1,2}):(\\d{2})');
          final match = pattern.firstMatch(businessHours);
          if (match != null && currentWeekday == entry.value) {
            final openHour = int.parse(match.group(1)!);
            final openMinute = int.parse(match.group(2)!);
            final closeHour = int.parse(match.group(3)!);
            final closeMinute = int.parse(match.group(4)!);
            
            final openTime = openHour * 60 + openMinute;
            final closeTime = closeHour * 60 + closeMinute;
            
            final isOpen = currentTimeInMinutes >= openTime && currentTimeInMinutes < closeTime;
            AppLogger.d('BusinessHoursParser: ${entry.key} hours $openHour:$openMinute-$closeHour:$closeMinute, currently ${isOpen ? "OPEN" : "CLOSED"}');
            return isOpen;
          }
        }
      }
      
      // 파싱 실패 시 기본값
      AppLogger.w('BusinessHoursParser: Could not parse business hours: "$businessHours"');
      return _defaultBusinessHours(currentWeekday, currentTimeInMinutes);
      
    } catch (e) {
      AppLogger.e('BusinessHoursParser: Error parsing business hours', e);
      return _defaultBusinessHours(currentWeekday, currentTimeInMinutes);
    }
  }
  
  static List<int> _extractClosedDays(String businessHours) {
    List<int> closedDays = [];
    
    for (final entry in weekdayMap.entries) {
      if (businessHours.contains('${entry.key} 휴무') || 
          businessHours.contains('${entry.key}휴무') ||
          businessHours.contains('(${entry.key} 휴무)')) {
        closedDays.add(entry.value);
      }
    }
    
    return closedDays;
  }
  
  static bool _defaultBusinessHours(int weekday, int currentTimeInMinutes) {
    // 기본 영업시간: 평일 10-20, 주말 10-18
    if (weekday >= 1 && weekday <= 5) {
      final isOpen = currentTimeInMinutes >= 600 && currentTimeInMinutes < 1200; // 10:00-20:00
      AppLogger.d('BusinessHoursParser: Using default weekday hours 10:00-20:00, currently ${isOpen ? "OPEN" : "CLOSED"}');
      return isOpen;
    } else {
      final isOpen = currentTimeInMinutes >= 600 && currentTimeInMinutes < 1080; // 10:00-18:00
      AppLogger.d('BusinessHoursParser: Using default weekend hours 10:00-18:00, currently ${isOpen ? "OPEN" : "CLOSED"}');
      return isOpen;
    }
  }
  
  static bool isLunchTime(String? businessHours) {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    // 기본 점심시간 체크 (12:00-13:00)
    if (currentHour == 12) {
      return true;
    }
    
    // businessHours에서 점심시간 정보 파싱 (추후 구현)
    // 예: "점심시간 12:00-13:00"
    
    return false;
  }
}