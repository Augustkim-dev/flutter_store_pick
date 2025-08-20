import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BusinessHoursWidget extends StatefulWidget {
  final Map<String, Map<String, String>>? businessHours;
  final ValueChanged<Map<String, Map<String, String>>> onHoursChanged;
  final List<String> closedDays;
  final ValueChanged<List<String>> onClosedDaysChanged;

  const BusinessHoursWidget({
    Key? key,
    this.businessHours,
    required this.onHoursChanged,
    required this.closedDays,
    required this.onClosedDaysChanged,
  }) : super(key: key);

  @override
  State<BusinessHoursWidget> createState() => _BusinessHoursWidgetState();
}

class _BusinessHoursWidgetState extends State<BusinessHoursWidget> {
  static const List<String> _weekDays = [
    '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'
  ];

  late Map<String, Map<String, String>> _hours;
  late List<String> _closedDays;
  bool _sameTimeForAll = false;
  TimeOfDay _uniformOpenTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _uniformCloseTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _initializeHours();
    _closedDays = List.from(widget.closedDays);
  }

  void _initializeHours() {
    _hours = {};
    for (var day in _weekDays) {
      if (widget.businessHours != null && widget.businessHours!.containsKey(day)) {
        _hours[day] = Map.from(widget.businessHours![day]!);
      } else {
        _hours[day] = {
          'open': '10:00',
          'close': '20:00',
          'break_start': '',
          'break_end': '',
        };
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(String day, String type) async {
    final currentTime = _hours[day]![type] ?? '10:00';
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 10,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        _hours[day]![type] = _formatTimeOfDay(picked);
      });
      widget.onHoursChanged(_hours);
    }
  }

  void _applyUniformTime() {
    setState(() {
      for (var day in _weekDays) {
        if (!_closedDays.contains(day)) {
          _hours[day] = {
            'open': _formatTimeOfDay(_uniformOpenTime),
            'close': _formatTimeOfDay(_uniformCloseTime),
            'break_start': _hours[day]!['break_start'] ?? '',
            'break_end': _hours[day]!['break_end'] ?? '',
          };
        }
      }
    });
    widget.onHoursChanged(_hours);
  }

  void _toggleDayClosed(String day) {
    setState(() {
      if (_closedDays.contains(day)) {
        _closedDays.remove(day);
      } else {
        _closedDays.add(day);
      }
    });
    widget.onClosedDaysChanged(_closedDays);
  }

  bool _isToday(String day) {
    final now = DateTime.now();
    final weekdayIndex = now.weekday;
    final todayName = _weekDays[weekdayIndex == 7 ? 6 : weekdayIndex - 1];
    return day == todayName;
  }

  bool _isBusinessHour(String day) {
    if (_closedDays.contains(day)) return false;
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final openTime = _hours[day]!['open'] ?? '10:00';
    final closeTime = _hours[day]!['close'] ?? '20:00';
    
    return currentTime.compareTo(openTime) >= 0 && currentTime.compareTo(closeTime) <= 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 일괄 설정
        Card(
          color: AppColors.primaryPink.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _sameTimeForAll,
                      onChanged: (value) {
                        setState(() {
                          _sameTimeForAll = value ?? false;
                        });
                      },
                      activeColor: AppColors.primaryPink,
                    ),
                    const Text('모든 요일 동일 시간'),
                  ],
                ),
                if (_sameTimeForAll) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      const Text('오픈: '),
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _uniformOpenTime,
                          );
                          if (picked != null) {
                            setState(() {
                              _uniformOpenTime = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(_formatTimeOfDay(_uniformOpenTime)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('마감: '),
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _uniformCloseTime,
                          );
                          if (picked != null) {
                            setState(() {
                              _uniformCloseTime = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(_formatTimeOfDay(_uniformCloseTime)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _applyUniformTime,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                        ),
                        child: const Text('적용'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 요일별 설정
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // 헤더
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.all(12),
                child: const Row(
                  children: [
                    SizedBox(width: 80, child: Text('요일', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 60, child: Text('휴무', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('영업시간', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    Expanded(child: Text('점심시간', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 요일별 행
              ...List.generate(_weekDays.length, (index) {
                final day = _weekDays[index];
                final isClosed = _closedDays.contains(day);
                final isToday = _isToday(day);
                final isOpen = isToday && _isBusinessHour(day);

                return Container(
                  color: isToday 
                    ? (isOpen ? Colors.green.shade50 : Colors.red.shade50)
                    : (index >= 5 ? Colors.blue.shade50 : null),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Row(
                                children: [
                                  Text(
                                    day,
                                    style: TextStyle(
                                      fontWeight: isToday ? FontWeight.bold : null,
                                      color: isToday 
                                        ? (isOpen ? Colors.green.shade700 : Colors.red.shade700)
                                        : null,
                                    ),
                                  ),
                                  if (isToday) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      isOpen ? Icons.circle : Icons.circle_outlined,
                                      size: 8,
                                      color: isOpen ? Colors.green : Colors.red,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Checkbox(
                                value: isClosed,
                                onChanged: (value) => _toggleDayClosed(day),
                                activeColor: Colors.red,
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: isClosed ? null : () => _selectTime(day, 'open'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isClosed ? Colors.grey.shade300 : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        color: isClosed ? Colors.grey.shade100 : null,
                                      ),
                                      child: Text(
                                        _hours[day]!['open'] ?? '10:00',
                                        style: TextStyle(
                                          color: isClosed ? Colors.grey : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Text('~'),
                                  ),
                                  InkWell(
                                    onTap: isClosed ? null : () => _selectTime(day, 'close'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isClosed ? Colors.grey.shade300 : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        color: isClosed ? Colors.grey.shade100 : null,
                                      ),
                                      child: Text(
                                        _hours[day]!['close'] ?? '20:00',
                                        style: TextStyle(
                                          color: isClosed ? Colors.grey : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: isClosed ? null : () => _selectTime(day, 'break_start'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isClosed ? Colors.grey.shade300 : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        color: isClosed ? Colors.grey.shade100 : null,
                                      ),
                                      child: Text(
                                        _hours[day]!['break_start']?.isEmpty ?? true
                                          ? '--:--'
                                          : _hours[day]!['break_start']!,
                                        style: TextStyle(
                                          color: isClosed ? Colors.grey : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Text('~'),
                                  ),
                                  InkWell(
                                    onTap: isClosed ? null : () => _selectTime(day, 'break_end'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isClosed ? Colors.grey.shade300 : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        color: isClosed ? Colors.grey.shade100 : null,
                                      ),
                                      child: Text(
                                        _hours[day]!['break_end']?.isEmpty ?? true
                                          ? '--:--'
                                          : _hours[day]!['break_end']!,
                                        style: TextStyle(
                                          color: isClosed ? Colors.grey : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < _weekDays.length - 1) const Divider(height: 1),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 현재 영업 상태
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                '현재 상태: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              Text(
                _getCurrentStatus(),
                style: TextStyle(color: Colors.green.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCurrentStatus() {
    final now = DateTime.now();
    final weekdayIndex = now.weekday;
    final todayName = _weekDays[weekdayIndex == 7 ? 6 : weekdayIndex - 1];
    
    if (_closedDays.contains(todayName)) {
      return '휴무일';
    }
    
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final openTime = _hours[todayName]!['open'] ?? '10:00';
    final closeTime = _hours[todayName]!['close'] ?? '20:00';
    final breakStart = _hours[todayName]!['break_start'] ?? '';
    final breakEnd = _hours[todayName]!['break_end'] ?? '';
    
    if (breakStart.isNotEmpty && breakEnd.isNotEmpty) {
      if (currentTime.compareTo(breakStart) >= 0 && currentTime.compareTo(breakEnd) <= 0) {
        return '점심시간 ($breakStart ~ $breakEnd)';
      }
    }
    
    if (currentTime.compareTo(openTime) >= 0 && currentTime.compareTo(closeTime) <= 0) {
      return '영업중 (오늘 $closeTime 마감)';
    } else if (currentTime.compareTo(openTime) < 0) {
      return '준비중 (오늘 $openTime 오픈)';
    } else {
      return '영업종료';
    }
  }
}