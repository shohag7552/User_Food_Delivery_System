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

  /// Height of the carousel itself. When [indicatorsBelow] is set the dot row
  /// adds to this rather than overlaying it, so the widget occupies slightly
  /// more than [height] in total.
  final double? height;

  /// Puts the dot indicators in a row beneath the carousel instead of floating
  /// them over the artwork.
  ///
  /// Worth doing whenever a page holds more than one banner: an overlay row is
  /// centred across the whole page, so with two tiles it hovers over the gap
  /// between them and belongs to neither. Below, it clearly refers to the page.
  final bool indicatorsBelow;

  /// How many banners share one carousel page.
  ///
  /// At the default of 1 the carousel behaves exactly as before. Above 1 the
  /// banners are chunked — `itemsPerPage: 2` shows (0,1), then (2,3) — so a
  /// swipe or autoplay tick advances by a whole page rather than one banner.
  ///
  /// Deliberately opt-in rather than inferred from [height]: the ecommerce
  /// hero and the promos panel also pass a height, and neither has the width
  /// to split.
  final int itemsPerPage;

  const PromotionalBanner({
    super.key,
    required this.banners,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.autoScrollDuration = const Duration(seconds: 4),
    this.height,
    this.itemsPerPage = 1,
    this.indicatorsBelow = false,
  }) : assert(itemsPerPage > 0);

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

  /// Number of carousel pages.
  ///
  /// With [PromotionalBanner.itemsPerPage] above 1 a page holds several
  /// banners, so this — not the banner total — is what the dots, autoplay and
  /// infinite-scroll flags must count. Two banners at `itemsPerPage: 2` are a
  /// single page: nothing to advance to, and one dot, not two.
  int get _pageCount => (widget.banners.length / widget.itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isWide = width >= 900;
    final double carouselHeight = widget.height ?? (isWide ? 200 : 160);

    if (widget.isLoading) return _buildLoadingState();
    if (widget.errorMessage != null) return _buildErrorState();
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final hasMultiplePages = _pageCount > 1;

    // White reads well over artwork but disappears against the page in light
    // mode, so the palette follows wherever the dots are actually drawn.
    final Color activeDot = widget.indicatorsBelow
        ? ColorResource.primaryDark
        : Colors.white;
    final Color inactiveDot = widget.indicatorsBelow
        ? context.textLight.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.5);

    final dots = hasMultiplePages
        ? List.generate(
            _pageCount,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? activeDot : inactiveDot,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )
        : <Widget>[];

    final showOverlayDots = dots.isNotEmpty && !widget.indicatorsBelow;

    final carousel = SizedBox(
      height: carouselHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: _pageCount,
            itemBuilder: (context, pageIndex, realIndex) => _buildPage(
              pageIndex,
              isWide: isWide,
              // Only an overlay row needs the caption lifted clear of it.
              hasDots: showOverlayDots,
            ),
            options: CarouselOptions(
              height: carouselHeight,
              viewportFraction: widget.height != null
                  ? 1.0
                  : (isWide ? 1 : 0.9),
              initialPage: 0,
              enableInfiniteScroll: hasMultiplePages,
              reverse: false,
              autoPlay: hasMultiplePages,
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
          if (showOverlayDots)
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

    if (!widget.indicatorsBelow || dots.isEmpty) return carousel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        carousel,
        const SizedBox(height: Constants.paddingSizeSmall),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: dots),
      ],
    );
  }

  /// One carousel page: up to [PromotionalBanner.itemsPerPage] banners laid
  /// out side by side and advanced together.
  Widget _buildPage(
    int pageIndex, {
    required bool isWide,
    required bool hasDots,
  }) {
    final start = pageIndex * widget.itemsPerPage;
    final slice = widget.banners.skip(start).take(widget.itemsPerPage).toList();

    // An odd banner count leaves the last page short. It spans the full width
    // rather than sitting half-width beside an empty slot, which would read as
    // a failed image rather than a deliberate layout.
    if (slice.length == 1) {
      return _buildBannerTile(slice.first, isWide: isWide, hasDots: hasDots);
    }

    final tiles = <Widget>[];
    for (var i = 0; i < slice.length; i++) {
      if (i > 0) {
        tiles.add(const SizedBox(width: Constants.paddingSizeDefault));
      }
      tiles.add(
        Expanded(
          child: _buildBannerTile(slice[i], isWide: isWide, hasDots: hasDots),
        ),
      );
    }
    return Row(children: tiles);
  }

  /// A single banner. Unchanged from the original single-per-page markup —
  /// only its wrapper differs now that a page can hold more than one.
  Widget _buildBannerTile(
    BannerModel banner, {
    required bool isWide,
    required bool hasDots,
  }) {
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
                          // Lift the caption clear of the dot overlay when it
                          // is showing.
                          bottom: hasDots ? 36 : 16,
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
