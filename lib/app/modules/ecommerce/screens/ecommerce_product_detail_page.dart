import 'package:kikomart_user_app/app/common/widgets/auth_dialog.dart';
import 'package:kikomart_user_app/app/common/widgets/custom_network_image.dart';
import 'package:kikomart_user_app/app/helper/session_manager.dart';
import 'package:kikomart_user_app/app/common/widgets/custom_toster.dart';
import 'package:kikomart_user_app/app/common/widgets/favorite_button.dart';
import 'package:kikomart_user_app/app/common/widgets/hover_arrow_carousel.dart';
import 'package:kikomart_user_app/app/common/widgets/rating_stars.dart';
import 'package:kikomart_user_app/app/common/widgets/web_footer.dart';
import 'package:kikomart_user_app/app/common/widgets/web_top_nav.dart';
import 'package:kikomart_user_app/app/controllers/auth_controller.dart';
import 'package:kikomart_user_app/app/controllers/brand_controller.dart';
import 'package:kikomart_user_app/app/controllers/cart_controller.dart';
import 'package:kikomart_user_app/app/controllers/flash_sale_controller.dart';
import 'package:kikomart_user_app/app/controllers/module_controller.dart';
import 'package:kikomart_user_app/app/controllers/product_controller.dart';
import 'package:kikomart_user_app/app/helper/localization_extension_helper.dart';
import 'package:kikomart_user_app/app/helper/price_helper.dart';
import 'package:kikomart_user_app/app/helper/routes/app_router.dart';
import 'package:kikomart_user_app/app/helper/share_helper.dart';
import 'package:kikomart_user_app/app/models/cart_item_model.dart';
import 'package:kikomart_user_app/app/models/flash_sale_item_model.dart';
import 'package:kikomart_user_app/app/models/product_model.dart';
import 'package:kikomart_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:kikomart_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:kikomart_user_app/app/modules/ecommerce/domain/services/variant_pricing.dart';
import 'package:kikomart_user_app/app/modules/ecommerce/widgets/ecommerce_product_card.dart';
import 'package:kikomart_user_app/app/modules/reviews/widgets/review_list_section.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
part '../widgets/product_detail_layout.dart';
part '../widgets/product_detail_parts.dart';

class EcommerceProductDetailPage extends StatefulWidget {
  final ProductModel product;

  /// The cart line this page was opened from (cart page). Its variations are
  /// pre-selected so the page shows — and updates — that exact line.
  final CartItemModel? cartItem;

  const EcommerceProductDetailPage({
    super.key,
    required this.product,
    this.cartItem,
  });

  @override
  State<EcommerceProductDetailPage> createState() =>
      _EcommerceProductDetailPageState();
}

class _EcommerceProductDetailPageState
    extends State<EcommerceProductDetailPage> {
  final PageController _galleryController = PageController();
  // Web scaffold key so the top-nav menu button can open the profile drawer.
  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();

  /// Expanded height of the mobile image header.
  static const double _expandedAppBarHeight = 340;

  /// Height reserved by the app bar's `bottom` (the refresh progress strip).
  static const double _appBarBottomHeight = 2;

  /// Scroll distance between fully expanded and fully collapsed. The status bar
  /// inset cancels out — it is part of both the max and min extent — so this is
  /// independent of the device.
  static const double _collapseDistance =
      _expandedAppBarHeight - kToolbarHeight - _appBarBottomHeight;

  final ScrollController _scrollController = ScrollController();

  /// 0 = header fully expanded (gallery on screen), 1 = fully collapsed.
  ///
  /// A [ValueNotifier] rather than `setState` so a scroll only rebuilds the two
  /// header buttons, not the whole product page. It also lets `leading` and
  /// `actions` react to the collapse — they sit outside `flexibleSpace`, so the
  /// ratio its LayoutBuilder computes is not reachable from there.
  final ValueNotifier<double> _collapseProgress = ValueNotifier<double>(0);
  int _currentImage = 0;
  bool _descExpanded = false;
  static const int _descCollapsedLines = 2;

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

  /// Shop products price by variation: a selected option's price replaces
  /// the base price instead of adding to it. Food products (if ever opened
  /// here) keep the additive base + extras model.
  bool get _variationIsPrice =>
      product.moduleType == ModuleController.ecommerce;

  /// "৳900 – ৳1,350", or a single price when both ends match.
  String _formatPriceRange(double low, double high) {
    if ((high - low).abs() < 0.005) return PriceHelper.formatPrice(low);
    return '${PriceHelper.formatPrice(low)} – ${PriceHelper.formatPrice(high)}';
  }

  /// Every currently selected option, across all groups.
  List<VariantOption> get _selectedOptions {
    final options = <VariantOption>[];
    for (final variant in product.variants) {
      final selection = _selectedVariants[variant.title];
      if (selection == null) continue;
      if (variant.type == 'radio') {
        options.add(selection as VariantOption);
      } else {
        options.addAll(selection as List<VariantOption>);
      }
    }
    return options;
  }

  /// Shop pricing for the current selection — before/after discount.
  VariantPricing get _variantPricing => VariantPricing.of(
    product,
    _selectedOptions,
    flashPrice: _flashItem?.flashPrice,
  );

  /// Per-unit price after discount.
  ///  • Shop: sum of the selected variation prices (or the base price when
  ///    none is priced), with the product discount / flash price applied.
  ///  • Food: discounted base (or flash price) + every selected option.
  double get _unitPrice {
    if (_variationIsPrice) return _variantPricing.finalPrice;
    final double base = _flashItem?.flashPrice ?? product.finalPrice;
    return _selectedOptions.fold(base, (sum, option) => sum + option.price);
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

  List<String> get _images => product.imageGallery.isNotEmpty
      ? product.imageGallery
      : [product.imageId];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final cartItem = widget.cartItem;
    if (cartItem != null) {
      _selectedVariants.addAll(_selectionFrom(cartItem.selectedVariants));
    }
    _syncQtyWithCart();
    _fetchProductDetails();
    _loadSuggested(widget.product.categoryId);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final progress =
        (_scrollController.offset / _collapseDistance).clamp(0.0, 1.0);
    // Skip sub-pixel churn — the buttons cannot show a 0.1% shadow change.
    if ((_collapseProgress.value - progress).abs() > 0.005) {
      _collapseProgress.value = progress;
    }
  }

  /// Progress through the final quarter of the collapse: 0 until the header is
  /// 75% collapsed, reaching 1 exactly when it is fully collapsed.
  ///
  /// Drives both halves of the hand-off from gallery to solid app bar — the
  /// button shadows fade out on it while the compact title fades in — so the
  /// two read as one movement instead of two unrelated transitions.
  static double _collapseHandoff(double collapseProgress) {
    const double fadeStart = 0.75;
    if (collapseProgress <= fadeStart) return 0;
    return ((collapseProgress - fadeStart) / (1 - fadeStart)).clamp(0.0, 1.0);
  }

  /// Drop-shadow strength for the floating header buttons. The shadow exists to
  /// lift them off the product photo, so it holds at full strength while the
  /// gallery is on screen and is gone by the time the solid app bar has taken
  /// over and is providing the contrast itself.
  static double _headerButtonShadowOpacity(double collapseProgress) =>
      1 - _collapseHandoff(collapseProgress);

  /// Loads the full, up-to-date product record by id from the Appwrite products
  /// table. Keeps the seeded model on failure so the page never goes blank.
  Future<void> _fetchProductDetails() async {
    setState(() => _isRefreshing = true);
    final fresh =
        await Get.find<ProductController>().getProductById(widget.product.id);
    if (!mounted) return;
    setState(() {
      if (fresh != null) {
        _product = fresh;
        // Options are matched by identity, so re-point the current selection
        // at the fresh product's options or the chips would lose it.
        final current = _buildSelectedVariants();
        _selectedVariants
          ..clear()
          ..addAll(_selectionFrom(current));
      }
      _isRefreshing = false;
    });
  }

  /// Rebuilds the in-memory selection map from saved variant selections,
  /// matching groups by title and options by name against [product]. Options
  /// that no longer exist are dropped.
  Map<String, dynamic> _selectionFrom(List<SelectedVariant> saved) {
    final result = <String, dynamic>{};
    for (final variant in product.variants) {
      final savedGroup =
          saved.firstWhereOrNull((s) => s.groupTitle == variant.title);
      if (savedGroup == null) continue;
      final names = savedGroup.selections.map((s) => s.optionName).toSet();
      final options =
          variant.options.where((o) => names.contains(o.name)).toList();
      if (options.isEmpty) continue;
      result[variant.title] =
          variant.type == 'radio' ? options.first : options;
    }
    return result;
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _collapseProgress.dispose();
    super.dispose();
  }

  /// The content band, shared with the top nav. At 1100 with a 24px inset the
  /// gallery sat 54px inside the bar above it on every side.
  static const double _maxContentWidth = WebTopNav.maxContentWidth;

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

  // ---------------------------------------------------------------------------
  // Shared building blocks (used by both mobile and web)
  // ---------------------------------------------------------------------------

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
        // Measure the real layout: the toggle appears only when the text
        // actually runs past the collapsed line count (line breaks and width
        // decide that, not character count).
        LayoutBuilder(
          builder: (context, constraints) {
            final style = poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textSecondary,
              height: 1.5,
            );
            final painter = TextPainter(
              text: TextSpan(text: description, style: style),
              maxLines: _descCollapsedLines,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: constraints.maxWidth);
            final bool overflows = painter.didExceedMaxLines;
            painter.dispose();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Text(
                    description,
                    maxLines: _descExpanded ? null : _descCollapsedLines,
                    overflow: _descExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
                if (overflows)
                  InkWell(
                    onTap: () =>
                        setState(() => _descExpanded = !_descExpanded),
                    borderRadius:
                        BorderRadius.circular(Constants.radiusSmall),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Constants.paddingSizeExtraSmall + 1,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _descExpanded ? 'see_less'.tr : 'see_more'.tr,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: ColorResource.primaryDark,
                            ),
                          ),
                          Icon(
                            _descExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: ColorResource.primaryDark,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Web / desktop layout
  // ---------------------------------------------------------------------------

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
              PositionedDirectional(
                top: 12,
                end: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _shareButton(),
                    const SizedBox(width: 10),
                    _circleButton(
                      child: FavoriteButton(product: product, size: 22),
                    ),
                  ],
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CustomNetworkImage(
                        image: images[index],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
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
                // Hand over the whole gallery so the viewer can swipe through
                // it, opening on the image that was tapped.
                extra: ImageViewerArgs(
                  images: images,
                  initialIndex: index,
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

  /// "10% OFF" / "৳100 OFF" for the product's own discount, or the live
  /// flash-sale saving (as a percentage) while a sale runs — the price row
  /// already carries the ⚡ badge. Null when sold at full price.
  String? get _discountLabel {
    final flashItem = _flashItem;
    if (flashItem != null) {
      if (product.price <= 0 || flashItem.flashPrice >= product.price) {
        return null;
      }
      final percent =
          ((product.price - flashItem.flashPrice) / product.price * 100)
              .round();
      return '$percent% ${'off'.tr.toUpperCase()}';
    }
    if (!product.hasDiscount) return null;
    final value = product.discountValue!;
    final amount = product.discountType == 'percentage'
        ? '${value % 1 == 0 ? value.toInt() : value}%'
        : PriceHelper.formatPrice(value);
    return '$amount ${'off'.tr.toUpperCase()}';
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
    final String? lineDiscountType;
    final double? lineDiscountValue;
    final double lineBasePrice;
    final double lineFinalPrice;
    if (_variationIsPrice) {
      // Shop: the line carries the variation-based unit price itself, so the
      // cart never adds the option prices on top again.
      final pricing = _variantPricing;
      lineBasePrice = pricing.basePrice;
      lineFinalPrice = pricing.finalPrice;
      lineDiscountType = flashItem != null
          ? 'fixed'
          : (pricing.hasDiscount ? product.discountType : null);
      lineDiscountValue = flashItem != null
          ? pricing.discountAmount
          : (pricing.hasDiscount ? product.discountValue : null);
    } else {
      lineBasePrice = product.price;
      lineDiscountType = flashItem != null ? 'fixed' : product.discountType;
      lineDiscountValue = flashItem != null
          ? (product.price > flashItem.flashPrice
              ? product.price - flashItem.flashPrice
              : 0)
          : product.discountValue;
      lineFinalPrice =
          flashItem != null ? flashItem.flashPrice : product.finalPrice;
    }

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
          basePrice: lineBasePrice,
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
          basePrice: lineBasePrice,
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
                          fontSize: Constants.fontSizeLarge,
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
                        width: 32,
                        child: Center(
                          child: Text(
                            '$_qty',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeDefault,
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
            const SizedBox(height: Constants.paddingSizeExtraSmall),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isAddingToCart ? null : () => _submitCart(matching),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResource.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    vertical: Constants.paddingSizeSmall,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Constants.radiusLarge),
                  ),
                ),
                icon: _isAddingToCart
                    ? const SizedBox(
                        width: 18,
                        height: 18,
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
                        size: 18,
                      ),
                label: Text(
                  isUpdate ? 'update_cart'.tr : 'add_to_cart'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeDefault,
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

}
