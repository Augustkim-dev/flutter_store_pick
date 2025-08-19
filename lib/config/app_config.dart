/// 앱 전체 설정 관리
/// 
/// 모든 API 키와 환경 설정을 중앙에서 관리합니다.
/// 나중에 .env 파일로 쉽게 마이그레이션할 수 있도록 구성되어 있습니다.
class AppConfig {
  // Private constructor
  AppConfig._();
  
  // ==================== API Keys ====================
  
  /// Naver Map API
  static const String naverMapClientId = 'aq7q955sfn';
  
  /// Supabase Configuration
  static const String supabaseUrl = 'https://dzfkgfdwskbindpmlbum.supabase.co';
  static const String supabaseAnonKey = 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR6ZmtnZmR3c2tiaW5kcG1sYnVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUzOTkwNDQsImV4cCI6MjA3MDk3NTA0NH0.letbe1mHeSbLSDvovjpA7QmurVMxPclhJeHYRnBJ24U';
  
  // ==================== Environment ====================
  
  /// 현재 환경 (development, staging, production)
  static const String environment = 'development';
  
  /// Debug 모드 여부
  static const bool isDebugMode = true;
  
  // ==================== App Settings ====================
  
  /// 앱 이름
  static const String appName = 'Ballet Shop Finder';
  
  /// 앱 버전
  static const String appVersion = '1.0.0';
  
  /// API 타임아웃 (초)
  static const int apiTimeoutSeconds = 30;
  
  /// 이미지 캐시 최대 크기 (MB)
  static const int imageCacheMaxSizeMB = 100;
  
  // ==================== Feature Flags ====================
  
  /// Supabase 사용 여부 (false면 더미 데이터 사용)
  static const bool useSupabase = true;
  
  /// 지도 기능 활성화 여부
  static const bool enableMapFeature = true;
  
  /// 리뷰 기능 활성화 여부
  static const bool enableReviewFeature = true;
  
  /// 즐겨찾기 기능 활성화 여부
  static const bool enableFavoriteFeature = true;
  
  // ==================== URLs ====================
  
  /// 개인정보 처리방침 URL
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  
  /// 이용약관 URL
  static const String termsOfServiceUrl = 'https://example.com/terms';
  
  /// 고객센터 URL
  static const String supportUrl = 'https://example.com/support';
  
  // ==================== Default Values ====================
  
  /// 기본 검색 반경 (미터)
  static const double defaultSearchRadiusMeters = 5000;
  
  /// 페이지당 아이템 수
  static const int itemsPerPage = 20;
  
  /// 리뷰 최소 글자 수
  static const int reviewMinLength = 10;
  
  /// 리뷰 최대 글자 수
  static const int reviewMaxLength = 500;
  
  // ==================== Helper Methods ====================
  
  /// 환경별 API URL 가져오기
  static String getApiUrl() {
    switch (environment) {
      case 'production':
        return supabaseUrl;
      case 'staging':
        return supabaseUrl; // 스테이징 URL로 변경 가능
      case 'development':
      default:
        return supabaseUrl;
    }
  }
  
  /// 디버그 메시지 출력
  static void debugPrint(String message) {
    if (isDebugMode) {
      print('[${DateTime.now().toIso8601String()}] $message');
    }
  }
  
  /// 설정 검증
  static bool validateConfig() {
    if (supabaseUrl.isEmpty) {
      throw Exception('Supabase URL is not configured');
    }
    if (supabaseAnonKey.isEmpty) {
      throw Exception('Supabase Anon Key is not configured');
    }
    if (naverMapClientId.isEmpty) {
      throw Exception('Naver Map Client ID is not configured');
    }
    return true;
  }
}