import 'app_config.dart';

/// Supabase 설정
/// AppConfig에서 값을 가져와 사용합니다.
class SupabaseConfig {
  static String get supabaseUrl => AppConfig.supabaseUrl;
  static String get supabaseAnonKey => AppConfig.supabaseAnonKey;
}