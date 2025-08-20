import 'package:flutter/material.dart';
import '../models/review.dart';
import '../theme/app_colors.dart';

class ReviewItem extends StatelessWidget {
  final Review review;
  final VoidCallback? onEdit;
  final VoidCallback? onReply;
  final bool showShopName;
  final bool isShopOwnerView;

  const ReviewItem({
    super.key,
    required this.review,
    this.onEdit,
    this.onReply,
    this.showShopName = false,
    this.isShopOwnerView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 작성자 정보 및 평점
          Row(
            children: [
              // 프로필 이미지
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryPink.withAlpha(51),
                backgroundImage: review.userAvatar != null 
                  ? NetworkImage(review.userAvatar!) 
                  : null,
                child: review.userAvatar == null
                  ? const Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.primaryPink,
                    )
                  : null,
              ),
              const SizedBox(width: 12),
              
              // 이름 및 날짜
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? '익명',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 별점
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: index < review.rating ? Colors.amber : AppColors.gray,
                  );
                }),
              ),
              
              // 수정 버튼
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 20),
                  color: AppColors.gray,
                ),
            ],
          ),
          
          // 리뷰 내용
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          
          // 사장님 답글
          if (review.hasReply) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withAlpha(13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryPink.withAlpha(51),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '사장님',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(review.replyCreatedAt!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray,
                        ),
                      ),
                      if (review.replyUpdatedAt != null && 
                          review.replyUpdatedAt!.isAfter(
                            review.replyCreatedAt!.add(const Duration(seconds: 1))
                          )) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '(수정됨)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.replyContent!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isShopOwnerView && onReply != null) ...[
            // 답글 작성 버튼 (상점 주인만 보임)
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('답글 작성'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryPink,
                  side: BorderSide(color: AppColors.primaryPink.withAlpha(102)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '방금 전';
        }
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else {
      return '${(difference.inDays / 365).floor()}년 전';
    }
  }
}