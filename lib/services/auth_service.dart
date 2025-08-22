import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../utils/app_logger.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // 현재 사용자 정보
  User? get currentUser => _supabase.auth.currentUser;
  
  // 로그인 상태 스트림
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // 현재 사용자 프로필
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      // 프로필 조회
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (response != null) {
        return UserProfile.fromJson(response);
      } else {
        // 프로필이 없으면 생성
        AppLogger.d('Profile not found, creating new profile for user: ${user.id}');
        await _createProfile(
          userId: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'],
        );
        
        // 생성된 프로필 다시 조회
        final newProfile = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        
        return UserProfile.fromJson(newProfile);
      }
    } catch (e) {
      AppLogger.e('Error fetching/creating user profile', e);
      // 기본 프로필 반환
      return UserProfile(
        id: user.id,
        email: user.email,
        fullName: user.userMetadata?['full_name'],
        userType: UserType.general,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
  
  // 회원가입
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      
      // 프로필 생성
      if (response.user != null) {
        await _createProfile(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
        );
      }
      
      return response;
    } catch (e) {
      throw Exception('회원가입 실패: $e');
    }
  }
  
  // 로그인
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // 로그인 성공 후 프로필 확인 및 생성
      if (response.user != null) {
        await _ensureProfileExists(response.user!);
      }
      
      return response;
    } catch (e) {
      throw Exception('로그인 실패: $e');
    }
  }
  
  // 로그아웃
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('로그아웃 실패: $e');
    }
  }
  
  // 비밀번호 재설정 이메일 발송
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('비밀번호 재설정 이메일 발송 실패: $e');
    }
  }
  
  // 프로필 업데이트
  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');
    
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', user.id);
    } catch (e) {
      throw Exception('프로필 업데이트 실패: $e');
    }
  }
  
  // 프로필 생성 (내부 메서드)
  Future<void> _createProfile({
    required String userId,
    required String email,
    String? fullName,
  }) async {
    try {
      // 먼저 기존 프로필이 있는지 확인
      final existingProfile = await _supabase
          .from('profiles')
          .select('id, user_type')
          .eq('id', userId)
          .maybeSingle();
      
      if (existingProfile != null) {
        // 프로필이 이미 존재하면 스킵 (user_type 유지)
        AppLogger.d('Profile already exists for user: $userId with user_type: ${existingProfile['user_type']}');
        return;
      }
      
      // 프로필이 없으면 새로 생성
      await _supabase.from('profiles').insert({
        'id': userId,
        'full_name': fullName,
        'user_type': 'general',
      });
      AppLogger.d('Profile created successfully for user: $userId');
    } catch (e) {
      AppLogger.e('Error creating profile', e);
      // 이미 존재하는 경우는 무시
      if (!e.toString().contains('duplicate')) {
        rethrow;
      }
    }
  }
  
  // 프로필 존재 확인 및 생성
  Future<void> _ensureProfileExists(User user) async {
    try {
      AppLogger.d('Ensuring profile exists for user ${user.id}');
      
      // 먼저 기존 프로필이 있는지 확인
      final existingProfile = await _supabase
          .from('profiles')
          .select('id, user_type')
          .eq('id', user.id)
          .maybeSingle();
      
      if (existingProfile != null) {
        // 프로필이 이미 존재하면 user_type은 유지하고 updated_at만 업데이트
        AppLogger.d('Profile already exists for user ${user.id}, keeping user_type: ${existingProfile['user_type']}');
        await _supabase.from('profiles').update({
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      } else {
        // 프로필이 없으면 새로 생성
        AppLogger.d('Creating new profile for user ${user.id}');
        await _supabase.from('profiles').insert({
          'id': user.id,
          'full_name': user.userMetadata?['full_name'],
          'user_type': 'general',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      // 프로필 생성/업데이트 확인
      final profile = await _supabase
          .from('profiles')
          .select('id, user_type')
          .eq('id', user.id)
          .single();
      
      if (profile != null) {
        AppLogger.d('Profile confirmed for user ${user.id} with user_type: ${profile['user_type']}');
      } else {
        throw Exception('Profile creation failed for user ${user.id}');
      }
    } catch (e) {
      AppLogger.e('Error ensuring profile exists', e);
      // 재시도 (새 프로필 생성만)
      try {
        AppLogger.d('Retrying profile creation...');
        await _supabase.from('profiles').insert({
          'id': user.id,
          'user_type': 'general',
        }).onError((error, stackTrace) {
          AppLogger.e('Profile creation retry failed', error);
          return {};
        });
      } catch (retryError) {
        AppLogger.e('Profile creation retry also failed', retryError);
      }
    }
  }
  
  // 이메일 중복 확인
  Future<bool> isEmailAvailable(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      
      return response == null;
    } catch (e) {
      AppLogger.e('Error checking email availability', e);
      return false;
    }
  }
  
  // 사용자명 중복 확인
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      
      return response == null;
    } catch (e) {
      AppLogger.e('Error checking username availability', e);
      return false;
    }
  }
}