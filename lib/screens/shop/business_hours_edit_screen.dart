import 'package:flutter/material.dart';
import '../../models/business_hours.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';

class BusinessHoursEditScreen extends StatefulWidget {
  final String shopId;

  const BusinessHoursEditScreen({super.key, required this.shopId});

  @override
  State<BusinessHoursEditScreen> createState() =>
      _BusinessHoursEditScreenState();
}

class _BusinessHoursEditScreenState extends State<BusinessHoursEditScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<BusinessHours> _businessHours = [];
  bool _isLoading = true;

  final List<String> _dayNames = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    _loadBusinessHours();
  }

  Future<void> _loadBusinessHours() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabaseService.client
          .from('business_hours')
          .select()
          .eq('shop_id', widget.shopId)
          .order('day_of_week');

      final hours = (response as List)
          .map((json) => BusinessHours.fromJson(json))
          .toList();

      // 7일 모두 있는지 확인하고 없으면 생성
      final List<BusinessHours> completeHours = [];
      for (int i = 0; i < 7; i++) {
        final existing = hours.firstWhere(
          (h) => h.dayOfWeek == i,
          orElse: () => BusinessHours(
            id: '',
            shopId: widget.shopId,
            dayOfWeek: i,
            openTime: '09:00',
            closeTime: '18:00',
            isClosed: false,
          ),
        );
        completeHours.add(existing);
      }

      setState(() {
        _businessHours = completeHours;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('영업시간 로딩 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBusinessHours() async {
    setState(() => _isLoading = true);

    try {
      for (final hours in _businessHours) {
        if (hours.id.isEmpty) {
          // 새로 생성
          await _supabaseService.client.from('business_hours').insert({
            'shop_id': hours.shopId,
            'day_of_week': hours.dayOfWeek,
            'open_time': hours.openTime,
            'close_time': hours.closeTime,
            'is_closed': hours.isClosed,
          });
        } else {
          // 업데이트
          await _supabaseService.client
              .from('business_hours')
              .update({
                'open_time': hours.openTime,
                'close_time': hours.closeTime,
                'is_closed': hours.isClosed,
              })
              .eq('id', hours.id);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('영업시간이 저장되었습니다')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime(int dayIndex, bool isOpenTime) async {
    final currentHours = _businessHours[dayIndex];
    final initialTime = TimeOfDay(
      hour: int.parse((isOpenTime
              ? currentHours.openTime
              : currentHours.closeTime) ??
          '09:00'.split(':')[0]),
      minute: int.parse((isOpenTime
              ? currentHours.openTime
              : currentHours.closeTime) ??
          '09:00'.split(':')[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryPink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final timeString =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isOpenTime) {
          _businessHours[dayIndex] = BusinessHours(
            id: currentHours.id,
            shopId: currentHours.shopId,
            dayOfWeek: currentHours.dayOfWeek,
            openTime: timeString,
            closeTime: currentHours.closeTime,
            isClosed: currentHours.isClosed,
          );
        } else {
          _businessHours[dayIndex] = BusinessHours(
            id: currentHours.id,
            shopId: currentHours.shopId,
            dayOfWeek: currentHours.dayOfWeek,
            openTime: currentHours.openTime,
            closeTime: timeString,
            isClosed: currentHours.isClosed,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영업시간 설정'),
        backgroundColor: AppColors.primaryPink,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveBusinessHours,
              child: const Text(
                '저장',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading && _businessHours.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _businessHours.length,
              itemBuilder: (context, index) {
                final hours = _businessHours[index];
                final isWeekend = hours.dayOfWeek == 0 || hours.dayOfWeek == 6;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isWeekend
                                    ? Colors.red.shade100
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${_dayNames[hours.dayOfWeek]}요일',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isWeekend
                                      ? Colors.red.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: !hours.isClosed,
                              onChanged: (value) {
                                setState(() {
                                  _businessHours[index] = BusinessHours(
                                    id: hours.id,
                                    shopId: hours.shopId,
                                    dayOfWeek: hours.dayOfWeek,
                                    openTime: hours.openTime,
                                    closeTime: hours.closeTime,
                                    isClosed: !value,
                                  );
                                });
                              },
                              activeColor: AppColors.primaryPink,
                            ),
                          ],
                        ),
                        if (!hours.isClosed) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(index, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          hours.openTime ?? '09:00',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('~'),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(index, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          hours.closeTime ?? '18:00',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '휴무',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}