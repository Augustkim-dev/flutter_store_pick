import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../theme/app_colors.dart';
import 'announcement_edit_screen.dart';

class AnnouncementListScreen extends StatefulWidget {
  final String shopId;
  final String shopName;

  const AnnouncementListScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  List<Announcement> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);

    try {
      final announcements = await _announcementService.getShopAnnouncements(widget.shopId);
      setState(() {
        _announcements = announcements;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공지사항 로딩 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePin(Announcement announcement) async {
    final success = await _announcementService.toggleAnnouncementPin(
      announcement.id,
      !announcement.isPinned,
    );

    if (success) {
      _loadAnnouncements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              announcement.isPinned ? '고정이 해제되었습니다' : '공지가 고정되었습니다',
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleActive(Announcement announcement) async {
    final success = await _announcementService.toggleAnnouncementStatus(
      announcement.id,
      !announcement.isActive,
    );

    if (success) {
      _loadAnnouncements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              announcement.isActive ? '공지가 비활성화되었습니다' : '공지가 활성화되었습니다',
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공지사항 삭제'),
        content: const Text('이 공지사항을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _announcementService.deleteAnnouncement(announcement.id);

    if (success) {
      _loadAnnouncements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공지사항이 삭제되었습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항 관리'),
        backgroundColor: AppColors.primaryPink,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? _buildEmptyState()
              : _buildAnnouncementList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnnouncementEditScreen(
                shopId: widget.shopId,
              ),
            ),
          ).then((_) => _loadAnnouncements());
        },
        backgroundColor: AppColors.primaryPink,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.announcement_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '등록된 공지사항이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 공지사항을 작성해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementList() {
    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: announcement.isPinned ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: announcement.isPinned
                  ? BorderSide(color: AppColors.primaryPink.withAlpha(102), width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementEditScreen(
                      shopId: widget.shopId,
                      announcement: announcement,
                    ),
                  ),
                ).then((_) => _loadAnnouncements());
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (announcement.isPinned) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPink,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.push_pin, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  '고정됨',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(announcement.statusText),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            announcement.statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'pin':
                                _togglePin(announcement);
                                break;
                              case 'toggle':
                                _toggleActive(announcement);
                                break;
                              case 'edit':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AnnouncementEditScreen(
                                      shopId: widget.shopId,
                                      announcement: announcement,
                                    ),
                                  ),
                                ).then((_) => _loadAnnouncements());
                                break;
                              case 'delete':
                                _deleteAnnouncement(announcement);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'pin',
                              child: Row(
                                children: [
                                  Icon(
                                    announcement.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(announcement.isPinned ? '고정 해제' : '상단 고정'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    announcement.isActive ? Icons.visibility_off : Icons.visibility,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(announcement.isActive ? '비활성화' : '활성화'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('수정'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('삭제', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      announcement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      announcement.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          announcement.validPeriodText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '작성: ${_formatDate(announcement.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '활성':
        return Colors.green;
      case '비활성':
        return Colors.grey;
      case '예정':
        return Colors.blue;
      case '종료':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}