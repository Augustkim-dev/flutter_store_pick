import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class VersionService {
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;
  VersionService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  PackageInfo? _packageInfo;

  // Remote Config 키들
  static const String _minimumVersionKey = 'minimum_version';
  static const String _latestVersionKey = 'latest_version';
  static const String _forceUpdateKey = 'force_update';
  static const String _updateUrlAndroidKey = 'update_url_android';
  static const String _updateUrlIosKey = 'update_url_ios';
  static const String _updateMessageKey = 'update_message';
  static const String _maintenanceModeKey = 'maintenance_mode';
  static const String _maintenanceMessageKey = 'maintenance_message';

  Future<void> initialize() async {
    try {
      // Remote Config 초기화
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // 기본값 설정
      await _remoteConfig.setDefaults({
        _minimumVersionKey: '1.0.0',
        _latestVersionKey: '1.0.0',
        _forceUpdateKey: false,
        _updateUrlAndroidKey: '',
        _updateUrlIosKey: '',
        _updateMessageKey: '새로운 버전이 출시되었습니다.',
        _maintenanceModeKey: false,
        _maintenanceMessageKey: '서버 점검 중입니다. 잠시 후 다시 시도해주세요.',
      });

      // Remote Config 설정 - 개발 중에는 즉시 가져오기
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      // Remote Config 가져오기 및 활성화
      final bool updated = await _remoteConfig.fetchAndActivate();
      
      if (kDebugMode) {
        print('Remote Config fetch and activate: $updated');
        print('Force update value: ${_remoteConfig.getBool(_forceUpdateKey)}');
        print('Maintenance mode: ${_remoteConfig.getBool(_maintenanceModeKey)}');
      }

      // 패키지 정보 가져오기
      _packageInfo = await PackageInfo.fromPlatform();
      
      if (kDebugMode) {
        print('VersionService initialized');
        print('Current version: ${_packageInfo?.version}');
        print('Minimum version: ${_remoteConfig.getString(_minimumVersionKey)}');
        print('Latest version: ${_remoteConfig.getString(_latestVersionKey)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize VersionService: $e');
      }
    }
  }

  // 현재 앱 버전 가져오기
  String get currentVersion => _packageInfo?.version ?? '1.0.0';

  // 최소 필수 버전 가져오기
  String get minimumVersion => _remoteConfig.getString(_minimumVersionKey);

  // 최신 버전 가져오기
  String get latestVersion => _remoteConfig.getString(_latestVersionKey);

  // 강제 업데이트 여부
  bool get isForceUpdate => _remoteConfig.getBool(_forceUpdateKey);

  // 업데이트 메시지
  String get updateMessage => _remoteConfig.getString(_updateMessageKey);

  // 서버 점검 모드 여부
  bool get isMaintenanceMode => _remoteConfig.getBool(_maintenanceModeKey);

  // 서버 점검 메시지
  String get maintenanceMessage => _remoteConfig.getString(_maintenanceMessageKey);

  // 업데이트 URL 가져오기
  String get updateUrl {
    if (Platform.isAndroid) {
      return _remoteConfig.getString(_updateUrlAndroidKey);
    } else if (Platform.isIOS) {
      return _remoteConfig.getString(_updateUrlIosKey);
    }
    return '';
  }

  // 버전 체크 결과
  VersionCheckResult checkVersion() {
    if (kDebugMode) {
      print('=== checkVersion Debug ===');
      print('Maintenance mode check: $isMaintenanceMode');
      print('Current vs Minimum: ${_compareVersions(currentVersion, minimumVersion)}');
      print('Current vs Latest: ${_compareVersions(currentVersion, latestVersion)}');
    }
    
    // 서버 점검 모드 체크
    if (isMaintenanceMode) {
      if (kDebugMode) print('Returning: maintenance');
      return VersionCheckResult.maintenance;
    }

    // 현재 버전과 최소 버전 비교 - 최소 버전 미충족시 강제 업데이트
    if (_compareVersions(currentVersion, minimumVersion) < 0) {
      if (kDebugMode) print('Returning: forceUpdate (below minimum version)');
      return VersionCheckResult.forceUpdate;
    }

    // 현재 버전과 최신 버전 비교 - 최소 버전은 충족하지만 최신 버전이 아닌 경우 선택적 업데이트
    if (_compareVersions(currentVersion, latestVersion) < 0) {
      if (kDebugMode) print('Returning: optionalUpdate (newer version available)');
      return VersionCheckResult.optionalUpdate;
    }

    if (kDebugMode) print('Returning: upToDate');
    return VersionCheckResult.upToDate;
  }

  // 버전 비교 함수 (semantic versioning)
  // 반환값: -1 (v1 < v2), 0 (v1 == v2), 1 (v1 > v2)
  int _compareVersions(String v1, String v2) {
    try {
      List<int> parts1 = v1.split('.').map((e) => int.parse(e)).toList();
      List<int> parts2 = v2.split('.').map((e) => int.parse(e)).toList();

      // 버전 파트 수를 맞춤
      while (parts1.length < parts2.length) parts1.add(0);
      while (parts2.length < parts1.length) parts2.add(0);

      for (int i = 0; i < parts1.length; i++) {
        if (parts1[i] < parts2[i]) return -1;
        if (parts1[i] > parts2[i]) return 1;
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error comparing versions: $e');
      }
      return 0;
    }
  }

  // Remote Config 새로고침
  Future<void> refresh() async {
    try {
      // 강제로 새로 가져오기
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero, // 캐시 무시
      ));
      
      final bool updated = await _remoteConfig.fetchAndActivate();
      
      if (kDebugMode) {
        print('Remote Config refresh result: $updated');
        print('After refresh - Maintenance: ${_remoteConfig.getBool(_maintenanceModeKey)}');
        print('After refresh - Force update: ${_remoteConfig.getBool(_forceUpdateKey)}');
        print('After refresh - Latest version: ${_remoteConfig.getString(_latestVersionKey)}');
        print('After refresh - Minimum version: ${_remoteConfig.getString(_minimumVersionKey)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to refresh remote config: $e');
      }
    }
  }
}

// 버전 체크 결과 enum
enum VersionCheckResult {
  upToDate,       // 최신 버전
  optionalUpdate, // 선택적 업데이트
  forceUpdate,    // 강제 업데이트
  maintenance,    // 서버 점검
}