import 'package:flutter/material.dart';
import '../skeleton_loader.dart';

// Quick Stats Skeleton
class QuickStatsSkeleton extends StatelessWidget {
  const QuickStatsSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 110, // Increased height to prevent overflow
      child: Row(
        children: List.generate(
          4,
          (index) => Expanded(
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
                right: index == 3 ? 0 : 4,
              ),
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
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkeletonLoader(
                      width: 28,
                      height: 28,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    const SizedBox(height: 6),
                    const SkeletonLoader(
                      width: 36,
                      height: 18,
                    ),
                    const SizedBox(height: 4),
                    const SkeletonLoader(
                      width: 50,
                      height: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Event Carousel Skeleton
class EventCarouselSkeleton extends StatelessWidget {
  const EventCarouselSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SkeletonLoader(
            width: 120,
            height: 24,
          ),
        ),
        // Carousel
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.symmetric(horizontal: 4),
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
                  children: [
                    // Image
                    SkeletonLoader(
                      width: double.infinity,
                      height: 120,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonLoader(
                            width: 150,
                            height: 16,
                          ),
                          const SizedBox(height: 8),
                          const SkeletonLoader(
                            width: 100,
                            height: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// New Shops Skeleton
class NewShopsSkeleton extends StatelessWidget {
  const NewShopsSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SkeletonLoader(
            width: 100,
            height: 24,
          ),
        ),
        // Shop list
        ...List.generate(
          2,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
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
                // Shop image
                SkeletonLoader(
                  width: 60,
                  height: 60,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                // Shop info
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
                        width: 200,
                        height: 12,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SkeletonLoader(
                            width: 50,
                            height: 20,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(width: 8),
                          SkeletonLoader(
                            width: 50,
                            height: 20,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Announcements Skeleton
class AnnouncementsSkeleton extends StatelessWidget {
  const AnnouncementsSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SkeletonLoader(
            width: 80,
            height: 24,
          ),
        ),
        // Announcement list
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
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
            children: List.generate(
              3,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index < 2 ? 12 : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SkeletonLoader(
                          width: 150,
                          height: 14,
                        ),
                        const Spacer(),
                        SkeletonLoader(
                          width: 60,
                          height: 12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const SkeletonLoader(
                      width: double.infinity,
                      height: 12,
                    ),
                    if (index < 2)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Divider(height: 1),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Full Dashboard Skeleton
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Welcome message
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(
                  width: 150,
                  height: 28,
                ),
                const SizedBox(height: 8),
                const SkeletonLoader(
                  width: 250,
                  height: 16,
                ),
              ],
            ),
          ),
        ),
        // Quick stats
        const SliverToBoxAdapter(
          child: QuickStatsSkeleton(),
        ),
        // Event carousel
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: EventCarouselSkeleton(),
          ),
        ),
        // New shops
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: NewShopsSkeleton(),
          ),
        ),
        // Announcements
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: AnnouncementsSkeleton(),
          ),
        ),
      ],
    );
  }
}