import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ErrorType {
  network,
  server,
  notFound,
  permission,
  general,
}

class CustomErrorWidget extends StatelessWidget {
  final String? message;
  final ErrorType errorType;
  final VoidCallback? onRetry;
  final String? actionLabel;

  const CustomErrorWidget({
    Key? key,
    this.message,
    this.errorType = ErrorType.general,
    this.onRetry,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(),
            const SizedBox(height: 24),
            Text(
              _getTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? _getDefaultMessage(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel ?? '다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color color;

    switch (errorType) {
      case ErrorType.network:
        iconData = Icons.wifi_off;
        color = Colors.orange;
        break;
      case ErrorType.server:
        iconData = Icons.cloud_off;
        color = Colors.red;
        break;
      case ErrorType.notFound:
        iconData = Icons.search_off;
        color = Colors.grey;
        break;
      case ErrorType.permission:
        iconData = Icons.lock_outline;
        color = Colors.amber;
        break;
      case ErrorType.general:
      default:
        iconData = Icons.error_outline;
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 64,
        color: color,
      ),
    );
  }

  String _getTitle() {
    switch (errorType) {
      case ErrorType.network:
        return '네트워크 연결 오류';
      case ErrorType.server:
        return '서버 오류';
      case ErrorType.notFound:
        return '찾을 수 없음';
      case ErrorType.permission:
        return '권한 없음';
      case ErrorType.general:
      default:
        return '오류 발생';
    }
  }

  String _getDefaultMessage() {
    switch (errorType) {
      case ErrorType.network:
        return '인터넷 연결을 확인해주세요';
      case ErrorType.server:
        return '서버에 일시적인 문제가 발생했습니다.\n잠시 후 다시 시도해주세요';
      case ErrorType.notFound:
        return '요청하신 정보를 찾을 수 없습니다';
      case ErrorType.permission:
        return '이 작업을 수행할 권한이 없습니다';
      case ErrorType.general:
      default:
        return '예기치 않은 오류가 발생했습니다';
    }
  }
}

// 빈 상태 위젯
class EmptyStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final Widget? action;

  const EmptyStateWidget({
    Key? key,
    this.title,
    this.message,
    this.icon,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title ?? '데이터가 없습니다',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}