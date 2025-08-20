import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_colors.dart';
import '../services/version_service.dart';
import '../widgets/update_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isCheckingVersion = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
    
    // 버전 체크 및 화면 전환
    _checkVersionAndNavigate();
  }

  Future<void> _checkVersionAndNavigate() async {
    final stopwatch = Stopwatch()..start();
    
    setState(() {
      _isCheckingVersion = true;
    });

    // 버전 체크와 최소 표시 시간을 병렬로 처리
    final futures = <Future>[];
    
    // 버전 체크 Future
    VersionCheckResult? versionResult;
    VersionService? versionService;
    
    futures.add(
      Future(() async {
        try {
          // VersionService 초기화
          versionService = VersionService();
          await versionService!.initialize();
          
          // Remote Config 새로고침 (비동기적으로 처리)
          await versionService!.refresh();
          
          // 버전 체크
          versionResult = versionService!.checkVersion();
          
          if (kDebugMode) {
            print('===== Version Check Debug Info =====');
            print('Current version: ${versionService!.currentVersion}');
            print('Minimum version: ${versionService!.minimumVersion}');
            print('Latest version: ${versionService!.latestVersion}');
            print('Force update: ${versionService!.isForceUpdate}');
            print('Maintenance mode: ${versionService!.isMaintenanceMode}');
            print('Version check result: $versionResult');
            print('=====================================');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error during version check: $e');
          }
          versionResult = VersionCheckResult.upToDate; // 에러 시 기본값
        }
      })
    );
    
    // 최소 표시 시간 (2초 -> 0.5초로 단축)
    futures.add(
      Future.delayed(const Duration(milliseconds: 500))
    );
    
    // 병렬 실행 - 둘 중 더 오래 걸리는 것만큼 대기
    await Future.wait(futures);
    
    stopwatch.stop();
    if (kDebugMode) {
      print('⏱️ Splash screen displayed for ${stopwatch.elapsedMilliseconds}ms');
    }

    if (!mounted) return;
    
    try {
      // 버전에 따른 처리
      switch (versionResult ?? VersionCheckResult.upToDate) {
        case VersionCheckResult.forceUpdate:
          // 강제 업데이트 다이얼로그 표시
          if (versionService != null) {
            await UpdateDialog.showForceUpdateDialog(
              context,
              currentVersion: versionService!.currentVersion,
              requiredVersion: versionService!.minimumVersion,
              message: versionService!.updateMessage,
              updateUrl: versionService!.updateUrl,
            );
          }
          break;
        case VersionCheckResult.optionalUpdate:
          // 선택적 업데이트 다이얼로그 표시
          if (versionService != null) {
            await UpdateDialog.showOptionalUpdateDialog(
              context,
              currentVersion: versionService!.currentVersion,
              latestVersion: versionService!.latestVersion,
              message: versionService!.updateMessage,
              updateUrl: versionService!.updateUrl,
            );
          }
          // 다이얼로그 닫은 후 메인 화면으로 이동
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
          break;
        case VersionCheckResult.maintenance:
          // 서버 점검 다이얼로그 표시
          if (versionService != null) {
            await UpdateDialog.showMaintenanceDialog(
              context,
              message: versionService!.maintenanceMessage,
            );
          }
          break;
        case VersionCheckResult.upToDate:
        default:
          // 최신 버전이므로 메인 화면으로 이동
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in splash screen navigation: $e');
      }
      // 에러 발생시에도 메인 화면으로 이동
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVersion = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryPink,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로고 아이콘
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withAlpha(51),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront,
                        size: 70,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // 앱 이름
                    Text(
                      '발레플러스',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // 서브 타이틀
                    Text(
                      'Ballet+',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.white.withAlpha(204),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 버전 체크 중 표시
                    if (_isCheckingVersion)
                      Column(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '버전 확인 중...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.white.withAlpha(204),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}