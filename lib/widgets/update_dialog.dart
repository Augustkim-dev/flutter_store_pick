import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/version_service.dart';

class UpdateDialog {
  // 강제 업데이트 다이얼로그
  static Future<void> showForceUpdateDialog(
    BuildContext context, {
    required String currentVersion,
    required String requiredVersion,
    required String message,
    required String updateUrl,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 바깥 터치로 닫기 불가
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // 뒤로가기 버튼 무효화
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.system_update, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('업데이트 필요'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('현재 버전: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(currentVersion, style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('필수 버전: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(requiredVersion, style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '앱을 계속 사용하려면 업데이트가 필요합니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        // 앱 종료
                        SystemNavigator.pop();
                      },
                      child: const Text('종료', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (updateUrl.isNotEmpty) {
                          final Uri url = Uri.parse(updateUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('업데이트'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 선택적 업데이트 다이얼로그
  static Future<bool> showOptionalUpdateDialog(
    BuildContext context, {
    required String currentVersion,
    required String latestVersion,
    required String message,
    required String updateUrl,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.new_releases, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('새로운 버전 출시'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('현재 버전: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(currentVersion),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('최신 버전: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(latestVersion, style: TextStyle(color: Theme.of(context).primaryColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // 나중에 업데이트
              },
              child: const Text('나중에', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (updateUrl.isNotEmpty) {
                  final Uri url = Uri.parse(updateUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                }
                if (!context.mounted) return;
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('업데이트'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // 서버 점검 다이얼로그
  static Future<void> showMaintenanceDialog(
    BuildContext context, {
    required String message,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.construction, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text('서버 점검 중'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.engineering,
                  size: 80,
                  color: Colors.orange[300],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  '불편을 드려 죄송합니다.\n잠시 후 다시 시도해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () {
                    // 앱 종료
                    SystemNavigator.pop();
                  },
                  child: const Text('앱 종료'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 버전 체크 및 다이얼로그 표시
  static Future<void> checkAndShowUpdateDialog(BuildContext context) async {
    final versionService = VersionService();
    final result = versionService.checkVersion();

    switch (result) {
      case VersionCheckResult.forceUpdate:
        await showForceUpdateDialog(
          context,
          currentVersion: versionService.currentVersion,
          requiredVersion: versionService.minimumVersion,
          message: versionService.updateMessage,
          updateUrl: versionService.updateUrl,
        );
        break;
      case VersionCheckResult.optionalUpdate:
        await showOptionalUpdateDialog(
          context,
          currentVersion: versionService.currentVersion,
          latestVersion: versionService.latestVersion,
          message: versionService.updateMessage,
          updateUrl: versionService.updateUrl,
        );
        break;
      case VersionCheckResult.maintenance:
        await showMaintenanceDialog(
          context,
          message: versionService.maintenanceMessage,
        );
        break;
      case VersionCheckResult.upToDate:
        // 최신 버전이므로 아무것도 하지 않음
        break;
    }
  }
}