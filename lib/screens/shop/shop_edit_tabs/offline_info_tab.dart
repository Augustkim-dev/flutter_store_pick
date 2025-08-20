import 'package:flutter/material.dart';
import '../../../models/shop.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/business_hours_widget.dart';

class OfflineInfoTab extends StatefulWidget {
  final Shop shop;
  final TextEditingController addressController;
  final TextEditingController detailedLocationController;
  final TextEditingController businessHoursController;
  final TextEditingController lunchBreakStartController;
  final TextEditingController lunchBreakEndController;
  final TextEditingController directionsPublicController;
  final TextEditingController directionsWalkingController;
  final TextEditingController parkingInfoController;
  final bool parkingAvailable;
  final bool fittingAvailable;
  final bool wheelchairAccessible;
  final bool kidsFriendly;
  final ValueChanged<bool> onParkingChanged;
  final ValueChanged<bool> onFittingChanged;
  final ValueChanged<bool> onWheelchairChanged;
  final ValueChanged<bool> onKidsChanged;

  const OfflineInfoTab({
    super.key,
    required this.shop,
    required this.addressController,
    required this.detailedLocationController,
    required this.businessHoursController,
    required this.lunchBreakStartController,
    required this.lunchBreakEndController,
    required this.directionsPublicController,
    required this.directionsWalkingController,
    required this.parkingInfoController,
    required this.parkingAvailable,
    required this.fittingAvailable,
    required this.wheelchairAccessible,
    required this.kidsFriendly,
    required this.onParkingChanged,
    required this.onFittingChanged,
    required this.onWheelchairChanged,
    required this.onKidsChanged,
  });

  @override
  State<OfflineInfoTab> createState() => _OfflineInfoTabState();
}

class _OfflineInfoTabState extends State<OfflineInfoTab> {
  TimeOfDay? _lunchStart;
  TimeOfDay? _lunchEnd;
  Map<String, Map<String, String>> _businessHours = {};
  List<String> _closedDays = [];

  @override
  void initState() {
    super.initState();
    _initLunchTime();
    _initBusinessHours();
  }

  void _initBusinessHours() {
    // Initialize business hours from controller if available
    // This is a simplified initialization - you might want to parse the businessHoursController text
    _businessHours = {
      '월요일': {'open': '10:00', 'close': '20:00', 'break_start': '', 'break_end': ''},
      '화요일': {'open': '10:00', 'close': '20:00', 'break_start': '', 'break_end': ''},
      '수요일': {'open': '10:00', 'close': '20:00', 'break_start': '', 'break_end': ''},
      '목요일': {'open': '10:00', 'close': '20:00', 'break_start': '', 'break_end': ''},
      '금요일': {'open': '10:00', 'close': '20:00', 'break_start': '', 'break_end': ''},
      '토요일': {'open': '10:00', 'close': '18:00', 'break_start': '', 'break_end': ''},
      '일요일': {'open': '10:00', 'close': '18:00', 'break_start': '', 'break_end': ''},
    };
  }

  void _initLunchTime() {
    if (widget.lunchBreakStartController.text.isNotEmpty) {
      final parts = widget.lunchBreakStartController.text.split(':');
      if (parts.length == 2) {
        _lunchStart = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 12,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    if (widget.lunchBreakEndController.text.isNotEmpty) {
      final parts = widget.lunchBreakEndController.text.split(':');
      if (parts.length == 2) {
        _lunchEnd = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 13,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart 
        ? (_lunchStart ?? const TimeOfDay(hour: 12, minute: 0))
        : (_lunchEnd ?? const TimeOfDay(hour: 13, minute: 0)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _lunchStart = picked;
          widget.lunchBreakStartController.text = 
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        } else {
          _lunchEnd = picked;
          widget.lunchBreakEndController.text = 
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 오프라인이나 복합 상점이 아닌 경우 안내 메시지
    if (!widget.shop.isOffline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '오프라인 매장 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '오프라인 또는 온/오프라인 상점만 입력 가능합니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 위치 정보
          _buildSectionTitle('위치 정보'),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.addressController,
            decoration: const InputDecoration(
              labelText: '주소',
              hintText: '매장 주소를 입력하세요',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.detailedLocationController,
            decoration: const InputDecoration(
              labelText: '상세 위치',
              hintText: '예: 2층 201호, 지하 1층',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.stairs),
              helperText: '건물 내 구체적인 위치를 입력하세요',
            ),
          ),
          const SizedBox(height: 24),

          // 영업 시간
          _buildSectionTitle('영업 시간'),
          const SizedBox(height: 12),
          BusinessHoursWidget(
            businessHours: _businessHours,
            closedDays: _closedDays,
            onHoursChanged: (hours) {
              setState(() {
                _businessHours = hours;
                // Update controller with formatted hours
                _updateBusinessHoursController();
              });
            },
            onClosedDaysChanged: (days) {
              setState(() {
                _closedDays = days;
              });
            },
          ),
          const SizedBox(height: 24),

          // 편의시설
          _buildSectionTitle('편의시설'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('주차 가능'),
                  subtitle: const Text('매장 전용 주차장이 있습니다'),
                  value: widget.parkingAvailable,
                  onChanged: widget.onParkingChanged,
                  secondary: const Icon(Icons.local_parking),
                  activeColor: AppColors.primaryPink,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('시착 가능'),
                  subtitle: const Text('제품을 직접 착용해볼 수 있습니다'),
                  value: widget.fittingAvailable,
                  onChanged: widget.onFittingChanged,
                  secondary: const Icon(Icons.checkroom),
                  activeColor: AppColors.primaryPink,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('휠체어 접근 가능'),
                  subtitle: const Text('휠체어 이용자도 편하게 방문 가능합니다'),
                  value: widget.wheelchairAccessible,
                  onChanged: widget.onWheelchairChanged,
                  secondary: const Icon(Icons.accessible),
                  activeColor: AppColors.primaryPink,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('아동 동반 가능'),
                  subtitle: const Text('아이와 함께 방문하기 좋습니다'),
                  value: widget.kidsFriendly,
                  onChanged: widget.onKidsChanged,
                  secondary: const Icon(Icons.child_friendly),
                  activeColor: AppColors.primaryPink,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 주차 정보 (주차 가능한 경우만)
          if (widget.parkingAvailable) ...[
            TextFormField(
              controller: widget.parkingInfoController,
              decoration: const InputDecoration(
                labelText: '주차 정보',
                hintText: '예: 건물 지하 2층, 2시간 무료',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_parking),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
          ],

          // 오시는 길
          _buildSectionTitle('오시는 길'),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.directionsPublicController,
            decoration: const InputDecoration(
              labelText: '대중교통 안내',
              hintText: '예: 2호선 강남역 3번 출구에서 도보 5분',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions_subway),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.directionsWalkingController,
            decoration: const InputDecoration(
              labelText: '도보 경로',
              hintText: '예: 출구에서 직진 후 첫 번째 골목 우회전',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions_walk),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          // 도움말
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tip',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• 정확한 위치 정보는 고객 방문율을 높입니다\n'
                        '• 편의시설 정보는 고객 만족도를 향상시킵니다\n'
                        '• 오시는 길은 구체적으로 작성해주세요',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _updateBusinessHoursController() {
    // Convert business hours map to a formatted string
    final buffer = StringBuffer();
    final weekDays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    
    for (var day in weekDays) {
      if (_closedDays.contains(day)) {
        buffer.writeln('$day: 휴무');
      } else if (_businessHours.containsKey(day)) {
        final hours = _businessHours[day]!;
        buffer.write('$day: ${hours['open']}-${hours['close']}');
        if (hours['break_start']!.isNotEmpty && hours['break_end']!.isNotEmpty) {
          buffer.write(' (점심시간: ${hours['break_start']}-${hours['break_end']})');
        }
        buffer.writeln();
      }
    }
    
    widget.businessHoursController.text = buffer.toString().trim();
  }
}