import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../theme/app_colors.dart';

class AnnouncementEditScreen extends StatefulWidget {
  final String shopId;
  final Announcement? announcement;

  const AnnouncementEditScreen({
    Key? key,
    required this.shopId,
    this.announcement,
  }) : super(key: key);

  @override
  State<AnnouncementEditScreen> createState() => _AnnouncementEditScreenState();
}

class _AnnouncementEditScreenState extends State<AnnouncementEditScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  
  bool _isPinned = false;
  bool _isActive = true;
  DateTime? _validFrom;
  DateTime? _validUntil;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement?.title);
    _contentController = TextEditingController(text: widget.announcement?.content);
    
    if (widget.announcement != null) {
      _isPinned = widget.announcement!.isPinned;
      _isActive = widget.announcement!.isActive;
      _validFrom = widget.announcement!.validFrom;
      _validUntil = widget.announcement!.validUntil;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final announcement = Announcement(
        id: widget.announcement?.id ?? '',
        shopId: widget.shopId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        isPinned: _isPinned,
        isActive: _isActive,
        validFrom: _validFrom,
        validUntil: _validUntil,
        createdAt: widget.announcement?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (widget.announcement == null) {
        // Create new announcement
        final result = await _announcementService.createAnnouncement(announcement);
        success = result != null;
      } else {
        // Update existing announcement
        success = await _announcementService.updateAnnouncement(
          widget.announcement!.id,
          announcement,
        );
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.announcement == null
                    ? '공지사항이 등록되었습니다'
                    : '공지사항이 수정되었습니다',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('저장에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final initialDate = isStartDate ? _validFrom : _validUntil;
    
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isStartDate ? '시작일 선택' : '종료일 선택',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: initialDate ?? DateTime.now(),
                selectedDayPredicate: (day) {
                  return isSameDay(initialDate, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    if (isStartDate) {
                      _validFrom = selectedDay;
                      // If end date is before start date, clear it
                      if (_validUntil != null && _validUntil!.isBefore(selectedDay)) {
                        _validUntil = null;
                      }
                    } else {
                      _validUntil = selectedDay;
                      // If start date is after end date, clear it
                      if (_validFrom != null && _validFrom!.isAfter(selectedDay)) {
                        _validFrom = null;
                      }
                    }
                  });
                  Navigator.of(context).pop();
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primaryPink.withAlpha(102),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (isStartDate) {
                          _validFrom = null;
                        } else {
                          _validUntil = null;
                        }
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('날짜 지우기'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.announcement == null ? '공지사항 작성' : '공지사항 수정'),
        backgroundColor: AppColors.primaryPink,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAnnouncement,
            child: const Text(
              '저장',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title input
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '공지사항 제목을 입력하세요',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '제목을 입력해주세요';
                }
                if (value.trim().length > 255) {
                  return '제목은 255자 이내로 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Content input
            TextFormField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '내용',
                hintText: '공지사항 내용을 입력하세요',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '내용을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Settings section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '공지 설정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pin to top
                    SwitchListTile(
                      title: const Text('상단 고정'),
                      subtitle: const Text('이 공지사항을 목록 상단에 고정합니다'),
                      value: _isPinned,
                      onChanged: (value) {
                        setState(() {
                          _isPinned = value;
                        });
                      },
                      activeColor: AppColors.primaryPink,
                    ),
                    
                    // Active status
                    SwitchListTile(
                      title: const Text('활성화'),
                      subtitle: const Text('이 공지사항을 고객에게 표시합니다'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: AppColors.primaryPink,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Date range section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '게시 기간',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '기간을 설정하지 않으면 상시 게시됩니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Start date
                    ListTile(
                      title: const Text('시작일'),
                      subtitle: Text(
                        _validFrom != null
                            ? _formatDate(_validFrom!)
                            : '설정하지 않음',
                        style: TextStyle(
                          color: _validFrom != null ? null : Colors.grey,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(true),
                    ),
                    
                    // End date
                    ListTile(
                      title: const Text('종료일'),
                      subtitle: Text(
                        _validUntil != null
                            ? _formatDate(_validUntil!)
                            : '설정하지 않음',
                        style: TextStyle(
                          color: _validUntil != null ? null : Colors.grey,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAnnouncement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.announcement == null ? '공지사항 등록' : '공지사항 수정',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}