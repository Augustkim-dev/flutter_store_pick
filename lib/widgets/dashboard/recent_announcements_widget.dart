import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../theme/app_colors.dart';
import '../../screens/shop_detail_screen_v2.dart';

class RecentAnnouncementsWidget extends StatelessWidget {
  final List<Announcement> announcements;

  const RecentAnnouncementsWidget({super.key, required this.announcements});

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(color: AppColors.primaryPink, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text('최신 공지사항', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: announcements.length > 5 ? 5 : announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            return _buildAnnouncementTile(context, announcement);
          },
        ),
      ],
    );
  }

  Widget _buildAnnouncementTile(BuildContext context, Announcement announcement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => ShopDetailScreenV2(shopId: announcement.shopId)));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon or Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: announcement.isImportant ? Colors.red.withAlpha(26) : AppColors.primaryPink.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  announcement.isImportant ? Icons.priority_high : Icons.campaign,
                  color: announcement.isImportant ? Colors.red : AppColors.primaryPink,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop name and date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (announcement.shopName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              announcement.shopName!,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        Text(
                          _getTimeAgo(announcement.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Title
                    Text(
                      announcement.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Content preview
                    Text(
                      announcement.content,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Badges
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (announcement.isPinned)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(26),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.push_pin, size: 10, color: Colors.orange),
                                SizedBox(width: 2),
                                Text(
                                  '고정',
                                  style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        if (announcement.isImportant)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(26),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '중요',
                              style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.month}월 ${dateTime.day}일';
    }
  }
}
