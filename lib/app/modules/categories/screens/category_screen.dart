import 'dart:math' as math;

import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/common/widgets/web_footer.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/category_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/dashboard_shimmer.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  /// Matches the top nav's own content band. At 1100 the body sat ~50px
  /// narrower than the bar above it, so the logo and the first category tile
  /// did not share a left edge.
  static const double _maxContentWidth = WebTopNav.maxContentWidth;

  /// Columns in the desktop-web grid.
  ///
  /// Fixed rather than derived from a tile width: the body is now capped to the
  /// nav's band, so the row width is known and a straight division gives tiles
  /// of a predictable size — ~218px at the full cap, which a two-line category
  /// name sits in comfortably.
  static const int _webColumns = 5;

  /// Gap between tiles. Unchanged from the value the grid has always used.
  static const double _webTileSpacing = 18;

  /// How much of a shop tile its artwork is allowed to take, and the ceiling
  /// it may never pass.
  ///
  /// The storefront home draws these very images at 30 and 60 pixels, so they
  /// are icon-sized files. Letting one fill a ~250px tile magnifies its pixels
  /// rather than showing more of it; held near its natural size it stays
  /// crisp, and the tile's tinted plate reads as deliberate space around it.
  static const double _ecommerceArtworkScale = 0.58;
  static const double _maxEcommerceArtwork = 110;

  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();

  /// Whether the shop storefront is the active one.
  bool get _isEcommerce => Get.find<ModuleController>().isEcommerce;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<CategoryController>();
    if (controller.categories.isEmpty && !controller.isLoading) {
      controller.getCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web shell (with the shared top-nav) only on desktop web — mobile,
    // tablets and narrow browser windows use the regular mobile scaffold.
    final useWebShell = WebTopNav.isEnabled(context);
    return useWebShell ? _buildWebScaffold() : _buildMobileScaffold();
  }

  Widget _buildMobileScaffold() {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'categories'.tr,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
        backgroundColor: ColorResource.primaryDark,
        foregroundColor: ColorResource.textWhite,
        elevation: 0,
      ),
      body: GetBuilder<CategoryController>(
        builder: (controller) {
          final stateView = _buildStateView(controller);
          if (stateView != null) return stateView;

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 18,
              childAspectRatio: 0.7,
            ),
            itemCount: controller.categories.length,
            itemBuilder: (context, index) {
              final category = controller.categories[index];
              return _buildCategoryCard(context, category);
            },
          );
        },
      ),
    );
  }

  // ── Web/desktop: shared top-nav + centered, width-capped hover grid. ──
  Widget _buildWebScaffold() {
    return Scaffold(
      key: _webScaffoldKey,
      backgroundColor: context.scaffoldBackground,
      appBar: WebTopNav(
        selectedIndex: null,
        onDestinationSelected: (index) {
          DashboardTabs.open(context, index);
        },
        onMenuTap: () => _webScaffoldKey.currentState?.openEndDrawer(),
      ),
      endDrawer: const WebProfileDrawer(),
      body: GetBuilder<CategoryController>(
        builder: (controller) {
          final stateView = _buildStateView(controller);

          return LayoutBuilder(
            builder: (context, viewport) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewport.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxContentWidth,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: WebTopNav.contentInset,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    24,
                                    0,
                                    4,
                                  ),
                                  child: Text(
                                    'categories'.tr,
                                    style: poppinsBold.copyWith(
                                      fontSize: Constants.fontSizeOverLarge,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (stateView != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 60,
                                    ),
                                    child: Center(child: stateView),
                                  )
                                else
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(bottom: 40),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: _webColumns,
                                          crossAxisSpacing: _webTileSpacing,
                                          mainAxisSpacing: 20,
                                          childAspectRatio: 0.72,
                                        ),
                                    itemCount: controller.categories.length,
                                    itemBuilder: (context, index) {
                                      final category =
                                          controller.categories[index];
                                      return HoverLift(
                                        showShadow: false,
                                        borderRadius:
                                            Constants.radiusExtraLarge,
                                        child: _buildCategoryCard(
                                          context,
                                          category,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const WebFooter(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Loading / error / empty states shared by the mobile and web layouts.
  /// Returns null when categories are ready to be rendered.
  Widget? _buildStateView(CategoryController controller) {
    if (controller.isLoading && controller.categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: CategorySectionShimmer(),
      );
    }

    if (controller.errorMessage != null && controller.categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: ColorResource.error, size: 48),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => controller.getCategories(),
                child: Text(
                  'try_again'.tr,
                  style: poppinsBold.copyWith(color: ColorResource.primaryDark),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.categories.isEmpty) {
      return Center(
        child: Text(
          'no_categories_available'.tr,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textLight,
          ),
        ),
      );
    }

    return null;
  }

  /// The category artwork inside a tile's plate.
  ///
  /// Food categories are dish photography: they fill the plate edge to edge
  /// and crop, which is what a photograph wants and what this screen has
  /// always done.
  ///
  /// Shop categories are not photographs — they are the icon-sized files the
  /// storefront home draws at 30 and 60 pixels. Stretching one across the
  /// tile only magnified its pixels, so those are capped near their natural
  /// size and centred, and contained rather than cropped so a non-square icon
  /// keeps its whole shape. Sizing the box down also hands the decoder a
  /// smaller target, so it stops upscaling the bitmap on the way in.
  Widget _buildCategoryImage(BuildContext context, String image) {
    if (!_isEcommerce) {
      return CustomNetworkImage(
        image: image,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return LayoutBuilder(
      builder: (context, plate) {
        final double shortestSide = math.min(plate.maxWidth, plate.maxHeight);
        // An unbounded plate would make the scale meaningless; fall back to
        // the ceiling rather than to infinity.
        final double side = shortestSide.isFinite
            ? math.min(
                shortestSide * _ecommerceArtworkScale,
                _maxEcommerceArtwork,
              )
            : _maxEcommerceArtwork;

        return Center(
          child: SizedBox.square(
            dimension: side,
            child: CustomNetworkImage(
              image: image,
              width: side,
              height: side,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel category) {
    return CustomClickableWidget(
      onTap: () {
        context.pushNamed(
          RouteNames.category,
          pathParameters: {'id': category.id},
          extra: category,
        );
      },
      isBackgroundTransparent: true,
      child: Column(
        children: [
          Expanded(
            flex: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
                border: Border.all(
                  color: ColorResource.primaryLight.withValues(alpha: 0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  Constants.radiusExtraLarge - 2,
                ),
                child:
                    category.imagePath != null && category.imagePath!.isNotEmpty
                    ? _buildCategoryImage(context, category.imagePath!)
                    : Container(
                        color: context.cardBackground,
                        alignment: Alignment.center,
                        child: Icon(
                          // A cutlery glyph on a shop category read as a bug in
                          // itself. Matches the fallback the ecommerce home
                          // already uses for these same categories.
                          _isEcommerce
                              ? Icons.category_outlined
                              : Icons.restaurant_menu,
                          size: 32,
                          color: ColorResource.primaryDark,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: Text(
              category.nameMap.trLanguage,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
