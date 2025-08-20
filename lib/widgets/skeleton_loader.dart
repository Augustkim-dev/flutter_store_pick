import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.margin,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1, milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.grey.shade300.withOpacity(_animation.value),
                  Colors.grey.shade200.withOpacity(_animation.value),
                  Colors.grey.shade300.withOpacity(_animation.value),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ShopCard 스켈레톤
class ShopCardSkeleton extends StatelessWidget {
  const ShopCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 부분
          SkeletonLoader(
            width: double.infinity,
            height: 160,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          // 컨텐츠 부분
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                const SkeletonLoader(
                  width: 150,
                  height: 20,
                ),
                const SizedBox(height: 8),
                // 설명
                const SkeletonLoader(
                  width: double.infinity,
                  height: 14,
                ),
                const SizedBox(height: 4),
                const SkeletonLoader(
                  width: 200,
                  height: 14,
                ),
                const SizedBox(height: 12),
                // 위치/배송 정보
                const SkeletonLoader(
                  width: 120,
                  height: 12,
                ),
                const SizedBox(height: 8),
                // 브랜드 태그
                Row(
                  children: [
                    SkeletonLoader(
                      width: 60,
                      height: 24,
                      borderRadius: BorderRadius.circular(12),
                      margin: const EdgeInsets.only(right: 6),
                    ),
                    SkeletonLoader(
                      width: 60,
                      height: 24,
                      borderRadius: BorderRadius.circular(12),
                      margin: const EdgeInsets.only(right: 6),
                    ),
                    SkeletonLoader(
                      width: 60,
                      height: 24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 리스트 아이템 스켈레톤
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SkeletonLoader(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(
                  width: 120,
                  height: 16,
                ),
                const SizedBox(height: 8),
                const SkeletonLoader(
                  width: double.infinity,
                  height: 12,
                ),
                const SizedBox(height: 4),
                const SkeletonLoader(
                  width: 80,
                  height: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 상세 화면 스켈레톤
class DetailScreenSkeleton extends StatelessWidget {
  const DetailScreenSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          const SkeletonLoader(
            width: double.infinity,
            height: 250,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                const SkeletonLoader(
                  width: 200,
                  height: 24,
                ),
                const SizedBox(height: 12),
                // 평점
                const SkeletonLoader(
                  width: 100,
                  height: 16,
                ),
                const SizedBox(height: 16),
                // 설명
                const SkeletonLoader(
                  width: double.infinity,
                  height: 14,
                ),
                const SizedBox(height: 8),
                const SkeletonLoader(
                  width: double.infinity,
                  height: 14,
                ),
                const SizedBox(height: 8),
                const SkeletonLoader(
                  width: 150,
                  height: 14,
                ),
                const SizedBox(height: 24),
                // 정보 섹션들
                ...List.generate(3, (index) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: 100,
                      height: 18,
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                    SkeletonLoader(
                      width: double.infinity,
                      height: 40,
                      borderRadius: BorderRadius.circular(8),
                      margin: const EdgeInsets.only(bottom: 16),
                    ),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}