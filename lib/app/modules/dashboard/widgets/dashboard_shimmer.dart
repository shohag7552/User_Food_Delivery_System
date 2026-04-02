import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';

class DashboardShimmer extends StatefulWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const DashboardShimmer({super.key, required this.child, this.borderRadius});

  @override
  State<DashboardShimmer> createState() => _DashboardShimmerState();
}

class _DashboardShimmerState extends State<DashboardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(0);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: radius,
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(-1.2 + (_controller.value * 2.4), -0.2),
                end: Alignment(1.2 + (_controller.value * 2.4), 0.2),
                colors: [
                  ColorResource.textLight.withValues(alpha: 0.10),
                  ColorResource.textLight.withValues(alpha: 0.22),
                  ColorResource.textLight.withValues(alpha: 0.10),
                ],
                stops: const [0.1, 0.5, 0.9],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: child,
          ),
        );
      },
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: radius,
      ),
    );
  }
}

class BannerShimmer extends StatelessWidget {
  const BannerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Constants.radiusLarge);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DashboardShimmer(
        borderRadius: radius,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: ColorResource.cardBackground,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: ColorResource.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorResource.textLight.withValues(alpha: 0.08),
                        ColorResource.textLight.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 110,
                bottom: 42,
                child: ShimmerBox(
                  height: 20,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Positioned(
                left: 16,
                right: 150,
                bottom: 16,
                child: ShimmerBox(
                  height: 14,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategorySectionShimmer extends StatelessWidget {
  const CategorySectionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
        itemBuilder: (context, index) {
          return DashboardShimmer(
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            child: Container(
              width: 70,
              decoration: BoxDecoration(
                color: ColorResource.cardBackground,
                border: Border.all(
                  color: ColorResource.textLight.withValues(alpha: 0.12),
                ),
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 7,
                    child: ShimmerBox(
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(
                        Constants.radiusLarge,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: ShimmerBox(
                        width: 42,
                        height: 10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) =>
            const SizedBox(width: Constants.paddingSizeLarge),
        itemCount: 5,
      ),
    );
  }
}

class HorizontalFoodListShimmer extends StatelessWidget {
  final bool isPopular;

  const HorizontalFoodListShimmer({super.key, this.isPopular = false});

  @override
  Widget build(BuildContext context) {
    final height = isPopular ? 290.0 : 220.0;
    final cardWidth = isPopular ? 208.0 : 200.0;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) => DashboardShimmer(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: cardWidth,
            decoration: BoxDecoration(
              color: ColorResource.cardBackground,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isPopular ? _PopularFoodCardSkeleton() : _FoodCardSkeleton(),
          ),
        ),
      ),
    );
  }
}

class _FoodCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: ShimmerBox(
            width: double.infinity,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Constants.radiusLarge),
              topRight: Radius.circular(Constants.radiusLarge),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerBox(height: 16, width: 120),
              SizedBox(height: 8),
              ShimmerBox(height: 12, width: 72),
            ],
          ),
        ),
      ],
    );
  }
}

class _PopularFoodCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 150,
          width: double.infinity,
          child: ShimmerBox(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerBox(height: 16, width: 130),
              SizedBox(height: 10),
              ShimmerBox(height: 14, width: 74),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(height: 16, width: 64),
                  ShimmerBox(height: 36, width: 36),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AllProductsGridShimmer extends StatelessWidget {
  final bool isTablet;

  const AllProductsGridShimmer({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isTablet ? 3 : 2;
    final itemCount = isTablet ? 6 : 4;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: isTablet ? 0.75 : 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => DashboardShimmer(
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            child: Container(
              decoration: BoxDecoration(
                color: ColorResource.cardBackground,
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: ShimmerBox(
                      width: double.infinity,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(Constants.radiusLarge),
                        topRight: Radius.circular(Constants.radiusLarge),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(height: 16, width: 120),
                        SizedBox(height: 8),
                        ShimmerBox(height: 12, width: 72),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          childCount: itemCount,
        ),
      ),
    );
  }
}

class LoadMoreShimmer extends StatelessWidget {
  const LoadMoreShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShimmer(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 120,
        height: 14,
        decoration: BoxDecoration(
          color: ColorResource.cardBackground,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
