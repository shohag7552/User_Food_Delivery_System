import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/dashboard_shimmer.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/models/banner_model.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PromotionalBanner extends StatefulWidget {
  final List<BannerModel> banners;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Duration autoScrollDuration;

  /// When provided, the widget renders in exactly this height and the dot
  /// indicators become an in-banner overlay rather than appearing below.
  final double? height;

  const PromotionalBanner({
    super.key,
    required this.banners,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.autoScrollDuration = const Duration(seconds: 4),
    this.height,
  });

  @override
  State<PromotionalBanner> createState() => _PromotionalBannerState();
}

class _PromotionalBannerState extends State<PromotionalBanner> {
  int _currentPage = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isWide = width >= 900;
    final double carouselHeight = widget.height ?? (isWide ? 200 : 160);

    if (widget.isLoading) return _buildLoadingState();
    if (widget.errorMessage != null) return _buildErrorState();
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final dots = widget.banners.length > 1
        ? List.generate(
            widget.banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )
        : <Widget>[];

    return SizedBox(
      height: carouselHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: widget.banners.length,
            itemBuilder: (context, index, realIndex) {
              final banner = widget.banners[index];
              return MouseRegion(
                // Web affordance: only actionable banners read as clickable.
                cursor: banner.hasAction
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                child: GestureDetector(
                  onTap: () {
                    if (banner.hasAction) _handleBannerTap(banner);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: widget.height != null
                        ? EdgeInsets.zero
                        : (isWide
                              ? null
                              : const EdgeInsets.symmetric(horizontal: 8)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        Constants.radiusLarge,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ColorResource.shadowMedium,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Constants.radiusLarge,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomNetworkImage(
                            image: banner.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                          if (banner.titleMap != null ||
                              banner.subTitleMap != null)
                            Positioned(
                              bottom: dots.isNotEmpty ? 36 : 16,
                              left: 16,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (banner.titleMap != null)
                                    Text(
                                      banner.titleMap.trLanguage,
                                      style: poppinsBold.copyWith(
                                        fontSize: Constants.fontSizeExtraLarge,
                                        color: ColorResource.textWhite,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (banner.subTitleMap != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      banner.subTitleMap.trLanguage,
                                      style: poppinsRegular.copyWith(
                                        fontSize: Constants.fontSizeSmall,
                                        color: ColorResource.textWhite,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: carouselHeight,
              viewportFraction: widget.height != null
                  ? 1.0
                  : (isWide ? 1 : 0.9),
              initialPage: 0,
              enableInfiniteScroll: widget.banners.length > 1,
              reverse: false,
              autoPlay: widget.banners.length > 1,
              autoPlayInterval: widget.autoScrollDuration,
              autoPlayAnimationDuration: const Duration(milliseconds: 1000),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: widget.height == null,
              enlargeFactor: 0.15,
              scrollDirection: Axis.horizontal,
              onPageChanged: (index, reason) {
                setState(() => _currentPage = index);
              },
            ),
          ),
          // Dot indicators as an in-banner overlay
          if (dots.isNotEmpty)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dots,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const BannerShimmer();
  }

  Widget _buildErrorState() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        border: Border.all(
          color: ColorResource.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: ColorResource.error, size: 40),
              const SizedBox(height: 12),
              Text(
                'Failed to load banners',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: context.textPrimary,
                ),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onRetry,
                  child: Text(
                    'Retry',
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Routes a banner tap by its action type: 'product' opens the product
  /// (detail page for ecommerce, bottom sheet for food), 'category' opens the
  /// category products page, 'url' opens the link externally (new tab on web).
  /// Only called when [BannerModel.hasAction] is true, so actionValue is set.
  Future<void> _handleBannerTap(BannerModel banner) async {
    final value = banner.actionValue!;
    print('====> Banner tapped: ${banner.actionType} - $value');

    switch (banner.actionType) {
      case 'product':
        // Resolve the product first: the right surface depends on its module.
        final product = await Get.find<ProductController>().getProductById(
          value,
        );
        if (!mounted) return;
        if (product == null) {
          customToster('product_not_found'.tr, isSuccess: false);
          return;
        }
        if (product.moduleType == ModuleController.ecommerce) {
          context.pushNamed(
            RouteNames.productDetail,
            pathParameters: {'id': product.id},
            extra: product,
          );
        } else {
          ProductDetailBottomSheet.show(context, product);
        }

      case 'category':
        // No extra: the category route hydrates itself from the id (loaded
        // list first, then a fetch), same as a deep link.
        context.pushNamed(RouteNames.category, pathParameters: {'id': value});

      case 'url':
        // Admin-entered links often omit the scheme ("www.example.com");
        // default those to https rather than rejecting them.
        final normalized = value.contains('://') ? value : 'https://$value';
        final uri = Uri.tryParse(normalized);
        if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
          debugPrint('Banner has invalid action url: $value');
          return;
        }
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
        if (!opened && mounted) {
          customToster('could_not_open_link'.tr, isSuccess: false);
        }

      default:
        debugPrint(
          'Unknown banner action: ${banner.actionType} - ${banner.actionValue}',
        );
    }
  }
}
