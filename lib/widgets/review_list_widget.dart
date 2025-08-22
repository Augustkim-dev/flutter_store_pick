import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class ReviewListWidget extends StatefulWidget {
  final String shopId;
  final bool showWriteButton;

  const ReviewListWidget({
    super.key,
    required this.shopId,
    this.showWriteButton = true,
  });

  @override
  State<ReviewListWidget> createState() => _ReviewListWidgetState();
}

class _ReviewListWidgetState extends State<ReviewListWidget> {
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final userProfile = await _authService.getCurrentUserProfile();
    setState(() {
      _currentUserId = userProfile?.id;
    });
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final reviews = await _reviewService.getShopReviews(widget.shopId);
      setState(() {
        _reviews = reviews;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showWriteButton && _currentUserId != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                // TODO: Shop 데이터를 가져와서 WriteReviewScreen에 전달
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('리뷰 작성 기능을 준비 중입니다'),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('리뷰 작성'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
              ),
            ),
          ),
        if (_reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                '아직 리뷰가 없습니다.\n첫 번째 리뷰를 작성해보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return _ReviewCard(
                review: review,
                isMyReview: review.userId == _currentUserId,
                onEdit: () async {
                  // TODO: Shop 데이터를 가져와서 WriteReviewScreen에 전달
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('리뷰 수정 기능을 준비 중입니다'),
                    ),
                  );
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('리뷰 삭제'),
                      content: const Text('이 리뷰를 삭제하시겠습니까?'),
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
                    await _reviewService.deleteReview(review.id);
                    _loadReviews();
                  }
                },
              );
            },
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final bool isMyReview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ReviewCard({
    required this.review,
    required this.isMyReview,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryPink.withValues(alpha: 0.1),
        child: Text(
          review.userName?.substring(0, 1) ?? 'U',
          style: const TextStyle(color: AppColors.primaryPink),
        ),
      ),
      title: Row(
        children: [
          Text(review.userName ?? '익명'),
          const SizedBox(width: 8),
          ...List.generate(
            5,
            (index) => Icon(
              index < review.rating ? Icons.star : Icons.star_border,
              size: 16,
              color: Colors.amber,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(review.comment ?? ''),
          const SizedBox(height: 4),
          Text(
            _formatDate(review.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: isMyReview
          ? PopupMenuButton(
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
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) {
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