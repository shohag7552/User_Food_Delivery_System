import 'package:appwrite_user_app/app/common/widgets/auth_dialog.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/helper/session_manager.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/common/widgets/favorite_button.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_arrow_carousel.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/common/widgets/web_footer.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/brand_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/flash_sale_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/models/flash_sale_item_model.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/widgets/ecommerce_product_card.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/review_list_section.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class EcommerceProductDetailPage extends StatefulWidget {
  final ProductModel product;

  const EcommerceProductDetailPage({super.key, required this.product});

  @override
  State<EcommerceProductDetailPage> createState() =>
      _EcommerceProductDetailPageState();
}

class _EcommerceProductDetailPageState
    extends State<EcommerceProductDetailPage> {
  final PageController _galleryController = PageController();
  // Web scaffold key so the top-nav menu button can open the profile drawer.
  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();
  int _currentImage = 0;
  bool _descExpanded = false;

  // Inline variant selection state. radio -> VariantOption, checkbox -> List.
  final Map<String, dynamic> _selectedVariants = {};
  final Map<String, GlobalKey> _variantKeys = {};
  String? _highlightedVariantTitle;
  int _qty = 1;
  bool _isAddingToCart = false;

  // Seeded with the model passed from the list (instant render), then refreshed
  // with the full record fetched by id from the Appwrite products table.
  late ProductModel _product = widget.product;
  bool _isRefreshing = false;

  // Suggested items from the same category.
  List<ProductModel> _suggested = [];
  bool _loadingSuggested = false;

  ProductModel get product => _product;

  bool get _hasVariants => product.variants.isNotEmpty;

  /// This product's entry in the currently running flash sale, or null.
  /// While non-null, the flash price overrides the product's own pricing
  /// everywhere on this page (display, totals, add-to-cart).
  FlashSaleItemModel? get _flashItem {
    if (!Get.isRegistered<FlashSaleController>()) return null;
    return Get.find<FlashSaleController>().itemForProduct(product.id);
  }

  /// Effective per-unit base: flash price during a live sale, else the
  /// product's own discounted price.
  double get _baseUnitPrice => _flashItem?.flashPrice ?? product.finalPrice;

  /// Per-unit price = effective base price + the additions of every selected
  /// variant option (radio adds one, checkbox adds each chosen option).
  double get _unitPrice {
    double extra = 0;
    for (final variant in product.variants) {
      final selection = _selectedVariants[variant.title];
      if (selection == null) continue;
      if (variant.type == 'radio') {
        extra += (selection as VariantOption).price;
      } else {
        for (final option in (selection as List<VariantOption>)) {
          extra += option.price;
        }
      }
    }
    return _baseUnitPrice + extra;
  }

  double get _totalPrice => _unitPrice * _qty;

  /// The first required group still missing a choice, or null when satisfied.
  VariantGroup? _firstUnselectedRequiredVariant() {
    for (final variant in product.variants) {
      if (variant.required && !_selectedVariants.containsKey(variant.title)) {
        return variant;
      }
    }
    return null;
  }

  /// Flattens the in-memory selection map into the cart's variant model.
  List<SelectedVariant> _buildSelectedVariants() {
    final result = <SelectedVariant>[];
    for (final variant in product.variants) {
      if (!_selectedVariants.containsKey(variant.title)) continue;
      final selections = <VariantSelection>[];
      if (variant.type == 'radio') {
        final option = _selectedVariants[variant.title] as VariantOption?;
        if (option != null) {
          selections.add(
            VariantSelection(optionName: option.name, optionPrice: option.price),
          );
        }
      } else {
        for (final option
            in (_selectedVariants[variant.title] as List<VariantOption>)) {
          selections.add(
            VariantSelection(optionName: option.name, optionPrice: option.price),
          );
        }
      }
      if (selections.isNotEmpty) {
        result.add(SelectedVariant(
          groupTitle: variant.title,
          groupType: variant.type,
          selections: selections,
        ));
      }
    }
    return result;
  }

  List<String> get _images => product.imageGallery.isNotEmpty
      ? product.imageGallery
      : [product.imageId];

  @override
  void initState() {
    super.initState();
    _syncQtyWithCart();
    _fetchProductDetails();
    _loadSuggested(widget.product.categoryId);
  }

  /// Loads the full, up-to-date product record by id from the Appwrite products
  /// table. Keeps the seeded model on failure so the page never goes blank.
  Future<void> _fetchProductDetails() async {
    setState(() => _isRefreshing = true);
    final fresh =
        await Get.find<ProductController>().getProductById(widget.product.id);
    if (!mounted) return;
    setState(() {
      if (fresh != null) _product = fresh;
      _isRefreshing = false;
    });
  }

  /// Loads related products from the same category, excluding the current one.
  Future<void> _loadSuggested(String categoryId) async {
    if (categoryId.isEmpty) return;
    setState(() => _loadingSuggested = true);
    try {
      final items = await Get.find<ProductController>()
          .getProductsByCategory(categoryId, limit: 12);
      if (!mounted) return;
      setState(() {
        _suggested =
            items.where((p) => p.id != widget.product.id).toList();
        _loadingSuggested = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSuggested = false);
    }
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  static const double _maxContentWidth = 1100;

  @override
  Widget build(BuildContext context) {
    // Web shell (with the shared top-nav) only on desktop web — mobile,
    // tablets and narrow browser windows use the regular mobile scaffold.
    final useWebShell = WebTopNav.isEnabled(context);
    return useWebShell
        ? _buildWebScaffold(context)
        : _buildMobileScaffold(context);
  }

  // ---------------------------------------------------------------------------
  // Mobile (unchanged)
  // ---------------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// Collapsing image header. Expanded it shows the swipeable gallery; once
  /// scrolled past it pins to a compact bar carrying the product name.
  Widget _buildSliverAppBar(BuildContext context) {
    const double expandedHeight = 340;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      elevation: 0,
      backgroundColor: context.cardBackground,
      surfaceTintColor: context.cardBackground,
      automaticallyImplyLeading: false,
      // Thin progress bar while refreshing from the database; reserves a
      // constant 2px so the bar height never jumps.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: _isRefreshing
            ? const LinearProgressIndicator(
                minHeight: 2,
                color: ColorResource.primaryDark,
                backgroundColor: Colors.transparent,
              )
            : const SizedBox(height: 2),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _circleButton(
          icon: Icons.arrow_back,
          onTap: () => context.pop(),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _circleButton(child: FavoriteButton(product: product, size: 22)),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double appBarHeight = constraints.maxHeight;
          final double statusBarHeight = MediaQuery.of(context).padding.top;
          final double minHeight = kToolbarHeight + statusBarHeight;
          final double collapseRatio =
              ((appBarHeight - minHeight) / (expandedHeight - minHeight))
                  .clamp(0.0, 1.0);
          final bool isCollapsed = collapseRatio < 0.1;

          return FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsetsDirectional.only(
              start: 72,
              end: 72,
              bottom: 16,
            ),
            title: isCollapsed
                ? Text(
                    product.nameMap.trLanguage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: context.textPrimary,
                    ),
                  )
                : null,
            background: _buildGallery(),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Main detail content stays inset; the suggested carousel below is
          // rendered full-bleed so it spans the whole screen width.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBrand(),
              _buildTitle(Constants.fontSizeExtraLarge),
              const SizedBox(height: 8),
              RatingStars(
                rating: product.avgRating,
                reviewCount: product.ratingCount,
                size: 16,
                showRating: true,
              ),
              const SizedBox(height: 12),
              _buildPriceRow(),
              const SizedBox(height: 10),
              _buildStockChip(),
              if (_hasVariants) _buildVariantsSection(),
              _buildDescriptionBlock(),
              _buildSpecs(),
              _buildReviewsBlock(),
            ],
          ),
        ),
        _buildSuggestedSection(),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared building blocks (used by both mobile and web)
  // ---------------------------------------------------------------------------

  Widget _buildTitle(double fontSize) {
    return Text(
      product.nameMap.trLanguage,
      style: poppinsBold.copyWith(
        fontSize: fontSize,
        color: context.textPrimary,
      ),
    );
  }

  /// Price row. During a live flash sale it shows the flash price with the
  /// original struck through and a ⚡ badge; rebuilt with the flash controller
  /// so pricing reverts the moment the sale's countdown expires.
  Widget _buildPriceRow() {
    return GetBuilder<FlashSaleController>(
      builder: (_) {
        final flashItem = _flashItem;
        final bool onFlashSale = flashItem != null;
        final double shownPrice =
            onFlashSale ? flashItem.flashPrice : product.finalPrice;
        final bool showOriginal = onFlashSale
            ? flashItem.flashPrice < product.price
            : product.hasDiscount;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              PriceHelper.formatPrice(shownPrice),
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeOverLarge,
                color: ColorResource.primaryDark,
              ),
            ),
            if (showOriginal) ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  PriceHelper.formatPrice(product.price),
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: context.textLight,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
            if (onFlashSale) ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: ColorResource.primaryGradient,
                    borderRadius:
                        BorderRadius.circular(Constants.radiusLarge),
                  ),
                  child: Text(
                    '⚡ ${'flash_sale'.tr}',
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeExtraSmall,
                      color: ColorResource.textWhite,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDescriptionBlock() {
    final description = product.descriptionMap.trLanguage.trim();
    if (description.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'description'.tr,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          maxLines: _descExpanded ? null : 4,
          overflow:
              _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textSecondary,
            height: 1.5,
          ),
        ),
        if (description.length > 160)
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _descExpanded ? 'see_less'.tr : 'see_more'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.primaryDark,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewsBlock() {
    if (product.ratingCount <= 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Divider(color: context.textLight.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text(
          'customer_reviews'.tr,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<String?>(
          future: Get.find<AuthController>().getUserId(),
          builder: (context, snapshot) => ReviewListSection(
            productId: product.id,
            currentUserId: snapshot.data,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Web / desktop layout
  // ---------------------------------------------------------------------------

  Widget _buildWebScaffold(BuildContext context) {
    return Scaffold(
      key: _webScaffoldKey,
      backgroundColor: context.scaffoldBackground,
      endDrawer: const WebProfileDrawer(),
      appBar: WebTopNav(
        // No tab is "active" on a sub-page.
        selectedIndex: null,
        // Tapping a destination returns to the dashboard and opens that tab.
        onDestinationSelected: (index) {
          DashboardTabs.open(context, index);
        },
        onMenuTap: () => _webScaffoldKey.currentState?.openEndDrawer(),
      ),
      body: LayoutBuilder(
        builder: (context, viewport) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewport.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top: gallery (left) + buy panel (right).
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: _buildWebGallery()),
                                const SizedBox(width: 36),
                                Expanded(flex: 6, child: _buildWebInfoColumn()),
                              ],
                            ),
                            // Full-width details below the two columns.
                            _buildDescriptionBlock(),
                            _buildSpecs(),
                            _buildReviewsBlock(),
                            // Suggested carousel constrained to the same content width.
                            _buildSuggestedSection(),
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
      ),
    );
  }

  /// Web gallery: a large square main image with a thumbnail strip beneath it.
  Widget _buildWebGallery() {
    final images = _images;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => _openWebImageDialog(context, _currentImage),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Constants.radiusLarge),
                  child: CustomNetworkImage(
                    image: images[_currentImage],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _circleButton(
                  child: FavoriteButton(product: product, size: 22),
                ),
              ),
              if (images.length > 1) ...[
                // Left Arrow
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _circleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        setState(() {
                          _currentImage = (_currentImage - 1 + images.length) % images.length;
                        });
                      },
                    ),
                  ),
                ),
                // Right Arrow
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _circleButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      onTap: () {
                        setState(() {
                          _currentImage = (_currentImage + 1) % images.length;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final selected = index == _currentImage;
                return GestureDetector(
                  onTap: () => setState(() => _currentImage = index),
                  child: Container(
                    width: 72,
                    height: 72,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? ColorResource.primaryDark
                            : context.textLight.withValues(alpha: 0.3),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: CustomNetworkImage(
                      image: images[index],
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _openWebImageDialog(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        int currentIndex = initialIndex;
        final images = _images;
        final transformationController = TransformationController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              backgroundColor: context.scaffoldBackground,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Product Image Viewport with Interactive zoom
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: InteractiveViewer(
                            transformationController: transformationController,
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: CustomNetworkImage(
                              image: images[currentIndex],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      // Floating Zoom + Close Toolbar overlay
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Zoom Out
                            _circleToolbarButton(
                              icon: Icons.zoom_out_rounded,
                              onTap: () {
                                final matrix = transformationController.value.clone();
                                final currentScale = matrix.getMaxScaleOnAxis();
                                final newScale = (currentScale - 0.25).clamp(1.0, 4.0);
                                setDialogState(() {
                                  transformationController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            // Zoom In
                            _circleToolbarButton(
                              icon: Icons.zoom_in_rounded,
                              onTap: () {
                                final matrix = transformationController.value.clone();
                                final currentScale = matrix.getMaxScaleOnAxis();
                                final newScale = (currentScale + 0.25).clamp(1.0, 4.0);
                                setDialogState(() {
                                  transformationController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            // Reset Zoom
                            _circleToolbarButton(
                              icon: Icons.restart_alt_rounded,
                              onTap: () {
                                setDialogState(() {
                                  transformationController.value = Matrix4.identity();
                                });
                              },
                            ),
                            const SizedBox(width: 16),
                            // Close Button
                            IconButton(
                              onPressed: () {
                                transformationController.dispose();
                                Navigator.pop(dialogContext);
                              },
                              icon: const Icon(Icons.close_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Left Navigation Arrow (inside card boundaries)
                      if (images.length > 1)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _circleButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () {
                              setDialogState(() {
                                currentIndex = (currentIndex - 1 + images.length) % images.length;
                                transformationController.value = Matrix4.identity(); // Reset zoom on image change
                              });
                            },
                          ),
                        ),

                      // Right Navigation Arrow (inside card boundaries)
                      if (images.length > 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: _circleButton(
                            icon: Icons.arrow_forward_ios_rounded,
                            onTap: () {
                              setDialogState(() {
                                currentIndex = (currentIndex + 1) % images.length;
                                transformationController.value = Matrix4.identity(); // Reset zoom on image change
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _circleToolbarButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onTap,
      ),
    );
  }

  /// Web right column: brand, title, rating, price, stock, variants and the
  /// purchase controls grouped in a card.
  Widget _buildWebInfoColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrand(),
        _buildTitle(Constants.fontSizeOverLarge),
        const SizedBox(height: 10),
        RatingStars(
          rating: product.avgRating,
          reviewCount: product.ratingCount,
          size: 16,
          showRating: true,
        ),
        const SizedBox(height: 16),
        _buildPriceRow(),
        const SizedBox(height: 14),
        _buildStockChip(),
        if (_hasVariants) _buildVariantsSection(),
        const SizedBox(height: 24),
        // Purchase controls in a subtle card (replaces the mobile bottom bar).
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            border: Border.all(
              color: context.textLight.withValues(alpha: 0.15),
            ),
          ),
          child: product.isOutOfStock
              ? _disabledButton('out_of_stock'.tr)
              : _buildPurchaseBar(),
        ),
      ],
    );
  }

  /// Horizontal carousel of related products from the same category, styled
  /// like the home carousels: larger cards on desktop web with hover-revealed
  /// scroll arrows that page the strip (hidden when everything already fits).
  /// Hidden entirely once we know there are no suggestions.
  Widget _buildSuggestedSection() {
    if (!_loadingSuggested && _suggested.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isWide = WebTopNav.isEnabled(context);
    final double cardWidth = isWide ? 230 : 170;
    final double stripHeight = isWide ? 350 : 280;
    final double horizontalPadding = isWide ? 0 : 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Divider(color: context.textLight.withValues(alpha: 0.2)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            'you_may_also_like'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeExtraLarge,
              color: context.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingSuggested)
          SizedBox(
            height: stripHeight,
            child: const Center(child: CircularProgressIndicator()),
          )
        else
          HoverArrowCarousel(
            height: stripHeight,
            builder: (context, carouselController) => ListView.separated(
              controller: carouselController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _suggested.length,
              // Full-bleed list: the inset lives inside the scroll view so
              // the first/last cards clear the edges while the list itself
              // spans the full section width.
              padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 8),
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) => SizedBox(
                width: cardWidth,
                child: EcommerceProductCard(product: _suggested[index]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _circleButton({IconData? icon, VoidCallback? onTap, Widget? child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.cardBackground.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child ??
            Icon(icon, size: 20, color: context.textPrimary),
      ),
    );
  }

  Widget _buildGallery() {
    final images = _images;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _galleryController,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _currentImage = i),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => context.pushNamed(
                RouteNames.imageViewer,
                extra: ImageViewerArgs(
                  imageUrl: images[index],
                  heroTag: 'ecom-${product.id}-$index',
                ),
              ),
              child: CustomNetworkImage(
                image: images[index],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
        // Subtle top scrim so the back/favorite buttons stay legible over
        // bright product images.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 110,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentImage == index ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentImage == index
                        ? ColorResource.primaryDark
                        : context.cardBackground.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBrand() {
    return GetBuilder<BrandController>(
      builder: (brandController) {
        final brand = brandController.brandById(product.brandId);
        if (brand == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            brand.nameMap.trLanguage.toUpperCase(),
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: ColorResource.primaryDark,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockChip() {
    final outOfStock = product.isOutOfStock;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (outOfStock ? ColorResource.error : ColorResource.success)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        outOfStock ? 'out_of_stock'.tr : '${product.stock} ${'in_stock'.tr}',
        style: poppinsMedium.copyWith(
          fontSize: Constants.fontSizeSmall,
          color: outOfStock ? ColorResource.error : ColorResource.success,
        ),
      ),
    );
  }

  Widget _buildSpecs() {
    final rows = <Widget>[];
    if ((product.sku ?? '').isNotEmpty) {
      rows.add(_specRow('sku'.tr, product.sku!));
    }
    if (product.weight != null) {
      rows.add(_specRow(
        'weight'.tr,
        '${product.weight}${product.weightUnit ?? ''}',
      ));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: context.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

  Widget _buildVariantsSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'customize_your_order'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ColorResource.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${product.variants.length} ${'groups'.tr}',
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeExtraSmall,
                    color: ColorResource.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'choose_your_preferred_options_to_build_the_perfect_order'.tr,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...product.variants.map(_buildVariantGroup),
        ],
      ),
    );
  }

  Widget _buildVariantGroup(VariantGroup variant) {
    final isHighlighted = _highlightedVariantTitle == variant.title;
    return AnimatedContainer(
      key: _variantKeys.putIfAbsent(variant.title, () => GlobalKey()),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 18),
      padding: EdgeInsets.all(isHighlighted ? 12 : 0),
      decoration: BoxDecoration(
        color: isHighlighted
            ? ColorResource.primaryDark.withValues(alpha: 0.04)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted
              ? ColorResource.primaryDark
              : Colors.transparent,
          width: isHighlighted ? 1.5 : 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row: "Size" with a Required marker, helper text on the right.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                variant.title,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: context.textPrimary,
                ),
              ),
              if (variant.required)
                Text(
                  ' *',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: ColorResource.error,
                  ),
                ),
              const Spacer(),
              Text(
                variant.required
                    ? 'select_one_option'.tr
                    : 'optional'.tr,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeExtraSmall,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Options as selectable chips.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: variant.options
                .map((option) => _buildOptionChip(variant, option))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip(VariantGroup variant, VariantOption option) {
    final isRadio = variant.type == 'radio';
    final bool isSelected;
    if (isRadio) {
      isSelected = _selectedVariants[variant.title] == option;
    } else {
      final selected =
          (_selectedVariants[variant.title] as List<VariantOption>?) ?? [];
      isSelected = selected.contains(option);
    }

    return GestureDetector(
      onTap: () => _onOptionTap(variant, option, isRadio: isRadio),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorResource.primaryDark
              : context.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ColorResource.primaryDark
                : context.textLight.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              option.name,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: isSelected
                    ? ColorResource.textWhite
                    : context.textPrimary,
              ),
            ),
            if (option.price > 0) ...[
              const SizedBox(width: 6),
              Text(
                '+${PriceHelper.formatPrice(option.price)}',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: isSelected
                      ? ColorResource.textWhite.withValues(alpha: 0.9)
                      : ColorResource.primaryDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onOptionTap(
    VariantGroup variant,
    VariantOption option, {
    required bool isRadio,
  }) {
    setState(() {
      if (isRadio) {
        _selectedVariants[variant.title] = option;
      } else {
        final selected =
            (_selectedVariants[variant.title] as List<VariantOption>?) ??
                <VariantOption>[];
        if (selected.contains(option)) {
          selected.remove(option);
          if (selected.isEmpty) {
            _selectedVariants.remove(variant.title);
          } else {
            _selectedVariants[variant.title] = selected;
          }
        } else {
          _selectedVariants[variant.title] = [...selected, option];
        }
      }
      // Clear the guidance highlight once the required choice is satisfied.
      if (_highlightedVariantTitle == variant.title &&
          _selectedVariants.containsKey(variant.title)) {
        _highlightedVariantTitle = null;
      }
    });
    // Reflect the cart quantity for the newly selected configuration.
    _syncQtyWithCart();
  }

  /// Scrolls to and pulses the given required group when the user tries to add
  /// without choosing it.
  void _guideToRequiredVariant(String title) {
    final ctx = _variantKeys[title]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
    setState(() => _highlightedVariantTitle = title);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && _highlightedVariantTitle == title) {
        setState(() => _highlightedVariantTitle = null);
      }
    });
  }

  /// Finds the cart line that matches the current product + selected options,
  /// or null if this exact configuration isn't in the cart yet.
  CartItemModel? _matchingCartItem() {
    final cart = Get.find<CartController>();
    final selected = _buildSelectedVariants();
    return cart.cartItems.firstWhereOrNull(
      (e) =>
          e.productId == product.id &&
          cart.areVariantsIdentical(e.selectedVariants, selected),
    );
  }

  /// Pulls the quantity for the current configuration from the cart so the page
  /// reflects what's already there when reopened (or after changing options).
  void _syncQtyWithCart() {
    final match = _matchingCartItem();
    if (!mounted) return;
    setState(() => _qty = match?.quantity ?? 1);
  }

  Future<void> _submitCart(CartItemModel? matching) async {
    // Adding to cart requires an account — prompt guests to sign in first.
    if (!isUserLoggedIn()) {
      AuthFlow.openLogin(context);
      return;
    }

    final missing = _firstUnselectedRequiredVariant();
    if (missing != null) {
      _guideToRequiredVariant(missing.title);
      customToster('please_select_required_options'.tr, isSuccess: false);
      return;
    }

    // During a live flash sale the line is priced at the flash price, written
    // as a fixed discount so cart/checkout/order records track the saving.
    final flashItem = _flashItem;
    if (flashItem != null && _qty > flashItem.remainingStock) {
      customToster('flash_sale_limit_reached'.tr, isSuccess: false);
      return;
    }
    final String? lineDiscountType =
        flashItem != null ? 'fixed' : product.discountType;
    final double? lineDiscountValue = flashItem != null
        ? (product.price > flashItem.flashPrice
            ? product.price - flashItem.flashPrice
            : 0)
        : product.discountValue;
    final double lineFinalPrice =
        flashItem != null ? flashItem.flashPrice : product.finalPrice;

    setState(() => _isAddingToCart = true);
    try {
      final userId = await Get.find<AuthController>().getUserId();
      if (matching != null) {
        // Already in cart — update the existing line to the chosen quantity
        // (and to the current pricing, so a flash price replaces a regular
        // one added earlier, and vice versa once the sale ends).
        final updated = matching.copyWith(
          selectedVariants: _buildSelectedVariants(),
          quantity: _qty,
          itemTotal: _totalPrice,
          basePrice: product.price,
          discountType: lineDiscountType,
          discountValue: lineDiscountValue,
          finalPrice: lineFinalPrice,
        );
        await Get.find<CartController>().updateCartItemDetails(updated);
        if (!mounted) return;
        customToster('cart_updated'.tr, isSuccess: true);
      } else {
        final cartItem = CartItemModel(
          id: '',
          userId: userId ?? '',
          productId: product.id,
          productName: product.nameMap.trLanguage,
          productImage: product.imageId,
          basePrice: product.price,
          discountType: lineDiscountType,
          discountValue: lineDiscountValue,
          finalPrice: lineFinalPrice,
          selectedVariants: _buildSelectedVariants(),
          quantity: _qty,
          itemTotal: _totalPrice,
          moduleType: product.moduleType,
        );
        await Get.find<CartController>().addToCart(cartItem);
        if (!mounted) return;
        customToster('added_to_cart'.tr, isSuccess: true);
      }
    } catch (_) {
      // CartController surfaces its own stock/identical messages.
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  /// Purchase bar for every product: live total + quantity stepper + add/update.
  /// Rebuilds with the cart so it always reflects the current cart state.
  Widget _buildPurchaseBar() {
    // During a live flash sale the stepper is capped at the sale's remaining
    // allocation as well as the product's own stock.
    final flashItem = _flashItem;
    final maxQty = flashItem == null
        ? product.stock
        : (flashItem.remainingStock < product.stock
            ? flashItem.remainingStock
            : product.stock);
    return GetBuilder<CartController>(
      builder: (_) {
        final matching = _matchingCartItem();
        final isUpdate = matching != null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUpdate ? 'in_cart'.tr : 'total'.tr,
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: context.textSecondary,
                        ),
                      ),
                      Text(
                        PriceHelper.formatPrice(_totalPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeOverLarge,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quantity stepper.
                Container(
                  decoration: BoxDecoration(
                    color: context.scaffoldBackground,
                    borderRadius: BorderRadius.circular(Constants.radiusLarge),
                    border: Border.all(
                      color: context.textLight.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      _qtyButton(
                        Icons.remove,
                        _qty > 1 ? () => setState(() => _qty--) : null,
                      ),
                      SizedBox(
                        width: 36,
                        child: Center(
                          child: Text(
                            '$_qty',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      _qtyButton(
                        Icons.add,
                        _qty < maxQty ? () => setState(() => _qty++) : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isAddingToCart ? null : () => _submitCart(matching),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResource.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Constants.radiusLarge),
                  ),
                ),
                icon: _isAddingToCart
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: ColorResource.textWhite,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Icon(
                        isUpdate
                            ? Icons.edit_outlined
                            : Icons.shopping_bag_outlined,
                        color: ColorResource.textWhite,
                        size: 20,
                      ),
                label: Text(
                  isUpdate ? 'update_cart'.tr : 'add_to_cart'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: ColorResource.textWhite,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: context.cardBackground,
        boxShadow: [
          BoxShadow(
            color: ColorResource.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: product.isOutOfStock
            ? _disabledButton('out_of_stock'.tr)
            : _buildPurchaseBar(),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? context.textLight
              : ColorResource.primaryDark,
        ),
      ),
    );
  }

  Widget _disabledButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor:
              context.textLight.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
          ),
        ),
        child: Text(
          label,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
      ),
    );
  }
}
