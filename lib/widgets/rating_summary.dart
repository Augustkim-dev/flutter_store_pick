import 'package:flutter/material.dart';
import '../models/review.dart';
import '../theme/app_colors.dart';

class RatingSummary extends StatelessWidget {
  final ShopRating? rating;

  const RatingSummary({
    super.key,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    if (rating == null || rating!.reviewCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gray.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            '아직 리뷰가 없습니다',
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

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
      child: Row(
        children: [
          // 평균 평점
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  rating!.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating!.averageRating.round() 
                        ? Icons.star 
                        : Icons.star_border,
                      size: 20,
                      color: Colors.amber,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '${rating!.reviewCount}개의 리뷰',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 24),
          
          // 별점 분포
          Expanded(
            flex: 3,
            child: Column(
              children: List.generate(5, (index) {
                final stars = 5 - index;
                final count = _getStarCount(stars);
                final percentage = rating!.getStarPercentage(stars);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$stars',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.gray.withAlpha(51),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: percentage,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  int _getStarCount(int stars) {
    switch (stars) {
      case 5:
        return rating!.fiveStarCount;
      case 4:
        return rating!.fourStarCount;
      case 3:
        return rating!.threeStarCount;
      case 2:
        return rating!.twoStarCount;
      case 1:
        return rating!.oneStarCount;
      default:
        return 0;
    }
  }
}