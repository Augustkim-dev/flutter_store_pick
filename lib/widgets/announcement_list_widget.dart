import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';
import '../theme/app_colors.dart';

class AnnouncementListWidget extends StatefulWidget {
  final String shopId;
  final String shopOwnerId;
  final bool isOwner;

  const AnnouncementListWidget({
    super.key,
    required this.shopId,
    required this.shopOwnerId,
    this.isOwner = false,
  });

  @override
  State<AnnouncementListWidget> createState() => _AnnouncementListWidgetState();
}

class _AnnouncementListWidgetState extends State<AnnouncementListWidget> {
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_announcements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '공지사항이 없습니다.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _announcements.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final announcement = _announcements[index];
        return _AnnouncementCard(
          announcement: announcement,
          isOwner: widget.isOwner,
          onEdit: widget.isOwner
              ? () async {
                  // 편집 화면으로 이동
                  final result = await Navigator.pushNamed(
                    context,
                    '/announcement-edit',
                    arguments: {
                      'shopId': widget.shopId,
                      'announcement': announcement,
                    },
                  );
                  if (result == true) {
                    _loadAnnouncements();
                  }
                }
              : null,
          onDelete: widget.isOwner
              ? () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('공지사항 삭제'),
                      content: const Text('이 공지사항을 삭제하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _announcementService.deleteAnnouncement(announcement.id);
                    _loadAnnouncements();
                  }
                }
              : null,
        );
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _AnnouncementCard({
    required this.announcement,
    required this.isOwner,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // 상세 보기 다이얼로그
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  if (announcement.isImportant)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '중요',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(announcement.title)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(announcement.content),
                    const SizedBox(height: 16),
                    Text(
                      _formatDate(announcement.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              actions: [
                if (isOwner) ...[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit?.call();
                    },
                    child: const Text('수정'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete?.call();
                    },
                    child: const Text('삭제'),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (announcement.isImportant)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '중요',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (announcement.isImportant) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOwner)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('수정'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('삭제'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit?.call();
                        } else if (value == 'delete') {
                          onDelete?.call();
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                announcement.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(announcement.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}