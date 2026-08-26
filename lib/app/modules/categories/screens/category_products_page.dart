import 'dart:math' as math;

import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/common/widgets/web_footer.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/cart_helper.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/models/category_model.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/food_card_metrics.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/food_item_card.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/widgets/ecommerce_product_card.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/common/widgets/directional_flip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class CategoryProductsPage extends StatefulWidget {
  final CategoryModel category;

  const CategoryProductsPage({super.key, required this.category});

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  static const int _pageSize = 10;

  /// Matches the top nav's own content band. At 1100 the body was ~50px
  /// narrower than the bar above it, so the logo and the first product column
  /// did not share a left edge — the kind of misalignment that reads as sloppy
  /// long before anyone works out why.
  static const double _maxContentWidth = WebTopNav.maxContentWidth;

  /// Side inset inside the cap. Equal to the nav's own leading inset, so the
  /// two line up rather than merely being the same width.
  static const double _sideInset = WebTopNav.contentInset;

  /// Height of a food card at [columns] across, derived from the real column
  /// width so the cards keep the proportions they have on the home page at any
  /// column count — [FoodCardMetrics.webCardHeight] assumes four.
  double _foodCardHeight(double screenWidth, int columns) {
    final contentWidth =
        math.min(screenWidth, _maxContentWidth) - _sideInset * 2;
    final cardWidth =
        (contentWidth - (columns - 1) * FoodCardMetrics.spacing) / columns;
    return cardWidth * FoodCardMetrics.imageAspect +
        FoodCardMetrics.detailsBlockHeight;
  }

  static const List<double> _staggerRatios = [1, 0.82, 1, 0.75, 0.9, 1, 0.8];

  double _imageRatioFor(int index) =>
      _staggerRatios[index % _staggerRatios.length];

  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  List<ProductModel> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProducts();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoading ||
        _isLoadingMore ||
        !_hasMore) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final products = await Get.find<ProductController>()
          .getProductsByCategory(
            widget.category.id,
            offset: _currentPage * _pageSize,
            limit: _pageSize,
          );
      setState(() {
        _products = products;
        _hasMore = products.length >= _pageSize;
        _currentPage = products.isEmpty ? 0 : 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final products = await Get.find<ProductController>()
          .getProductsByCategory(
            widget.category.id,
            offset: _currentPage * _pageSize,
            limit: _pageSize,
          );

      setState(() {
        _products.addAll(products);
        _hasMore = products.length >= _pageSize;
        if (products.isNotEmpty) {
          _currentPage++;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });

      Get.snackbar(
        'Error',
        'Failed to load more products',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorResource.error.withValues(alpha: 0.9),
        colorText: ColorResource.textWhite,
      );
    }
  }

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
      body: RefreshIndicator(
        color: ColorResource.primaryDark,
        onRefresh: () => _loadProducts(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar with Category Info
            _buildSliverAppBar(),

            // Products Grid
            if (_isLoading)
              SliverFillRemaining(child: _buildLoadingState())
            else if (_errorMessage != null)
              SliverFillRemaining(child: _buildErrorState())
            else if (_products.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverMainAxisGroup(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver:
                        Get.find<ModuleController>().activeModule ==
                            ModuleController.ecommerce
                        ? SliverMasonryGrid.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childCount: _products.length,
                            itemBuilder: (context, index) =>
                                EcommerceProductCard(
                                  product: _products[index],
                                  imageAspectRatio: _imageRatioFor(index),
                                ),
                          )
                        : SliverGrid(
                            // 0.65 is the ratio the home page's two-column
                            // phone grid uses, so a dish is the same shape
                            // wherever it is browsed from.
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.65,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildFoodCard(_products[index]),
                              childCount: _products.length,
                            ),
                          ),
                  ),
                  if (_isLoadingMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: ColorResource.primaryDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Web
  // ---------------------------------------------------------------------------

  Widget _buildWebScaffold(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Four columns at most. The content is capped at [_maxContentWidth], so a
    // fifth column does not widen the grid — it divides the same 1100px into
    // ~194px cards, which is too narrow for a product photo, a name, a rating
    // and a price row to coexist in.
    final crossAxisCount = width >= 1100 ? 4 : 3;

    late final Widget contentSliver;
    if (_isLoading) {
      contentSliver = SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: _buildLoadingState(),
        ),
      );
    } else if (_errorMessage != null) {
      contentSliver = SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: _buildErrorState(),
        ),
      );
    } else if (_products.isEmpty) {
      contentSliver = SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: _buildEmptyState(),
        ),
      );
    } else {
      contentSliver = SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(_sideInset, 0, _sideInset, 24),
            sliver:
                Get.find<ModuleController>().activeModule ==
                    ModuleController.ecommerce
                // No HoverLift here: the card runs its own pointer behaviour
                // (the hover image gallery), and two hover effects on one
                // target fight each other.
                ? SliverMasonryGrid.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childCount: _products.length,
                    itemBuilder: (context, index) => EcommerceProductCard(
                      product: _products[index],
                      imageAspectRatio: _imageRatioFor(index),
                    ),
                  )
                : SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: FoodCardMetrics.spacing,
                      mainAxisSpacing: FoodCardMetrics.spacing,
                      // A fixed height rather than a ratio, for the same reason
                      // the home grid uses one: the card's details block is a
                      // fixed size and only the image should absorb the slack.
                      mainAxisExtent: _foodCardHeight(width, crossAxisCount),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          HoverLift(child: _buildFoodCard(_products[index])),
                      childCount: _products.length,
                    ),
                  ),
          ),
          if (_isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: ColorResource.primaryDark,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Full-bleed scroll view (wheel and scrollbar work across the whole
    // screen, not just the middle column) — the content itself stays centered
    // within the cap via symmetric sliver gutters.
    final double gutter = width > _maxContentWidth
        ? (width - _maxContentWidth) / 2
        : 0;

    return Scaffold(
      key: _webScaffoldKey,
      backgroundColor: context.scaffoldBackground,
      endDrawer: const WebProfileDrawer(),
      appBar: WebTopNav(
        selectedIndex: null,
        onDestinationSelected: (index) {
          DashboardTabs.open(context, index);
        },
        onMenuTap: () => _webScaffoldKey.currentState?.openEndDrawer(),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: SliverToBoxAdapter(child: _buildWebHeader()),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: contentSliver,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              alignment: Alignment.bottomCenter,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [SizedBox(height: 40), WebFooter()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebHeader() {
    final description = widget.category.descriptionMap.trLanguage.trim();
    final hasImage = widget.category.imagePath?.isNotEmpty ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_sideInset, 24, _sideInset, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb: Home / <category>
          Row(
            children: [
              InkWell(
                onTap: () {
                  DashboardTabs.open(context, 0);
                },
                child: Text(
                  'home'.tr,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.primaryDark,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: context.textLight,
                ),
              ),
              Flexible(
                child: Text(
                  widget.category.nameMap.trLanguage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hero banner
          ClipRRect(
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    CustomNetworkImage(
                      image: widget.category.imagePath!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: ColorResource.primaryGradient,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.category.nameMap.trLanguage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeOverLarge,
                            color: ColorResource.textWhite,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: ColorResource.textWhite.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: ColorResource.primaryDark,
      leading: IconButton(
        icon: DirectionalFlip(
          child: Icon(Icons.arrow_back, color: ColorResource.textWhite),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.category.nameMap.trLanguage,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
        background: widget.category.imagePath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CustomNetworkImage(
                    image: widget.category.imagePath!,
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
                          ColorResource.primaryDark.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: ColorResource.primaryGradient,
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: ColorResource.primaryDark),
          const SizedBox(height: 16),
          Text(
            'Loading products...',
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: ColorResource.error),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: poppinsBold.copyWith(
                fontSize: 24,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _loadProducts(refresh: true),
              icon: const Icon(Icons.refresh),
              label: Text('try_again'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                foregroundColor: ColorResource.textWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusLarge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ColorResource.primaryDark.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.food_bank_outlined,
                size: 60,
                color: context.textLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Products Found',
              style: poppinsBold.copyWith(
                fontSize: 24,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any products in this category yet.\nCheck back soon!',
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: Text('go_back'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                foregroundColor: ColorResource.textWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusLarge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ecommerce items open their full detail page; food items keep the
  /// quick-view bottom sheet (dialog on desktop web).
  void _openProduct(ProductModel product) {
    if (product.moduleType == ModuleController.ecommerce) {
      context.pushNamed(
        RouteNames.productDetail,
        pathParameters: {'id': product.id},
        extra: product,
      );
    } else {
      ProductDetailBottomSheet.show(context, product);
    }
  }

  /// Food-module card: the exact card the home feed uses.
  ///
  /// Rebuilt against [CartController] so the inline quantity stepper reflects
  /// the cart the moment it changes — the same wiring the home sections use, so
  /// adding a dish here behaves identically to adding it there.
  Widget _buildFoodCard(ProductModel product) {
    return GetBuilder<CartController>(
      builder: (_) => FoodItemCard(
        name: product.nameMap.trLanguage,
        imageUrl: product.imageId,
        description: product.descriptionMap.trLanguage,
        price: product.finalPrice,
        oldPrice: product.hasDiscount ? product.price : null,
        product: product,
        cartQuantity: CartHelper.getProductCartQuantity(product.id),
        onTap: () => _openProduct(product),
        onAddToCart: () => CartHelper.handleAddToCart(product, context),
        onQuantityChanged: (isIncrement) {
          if (isIncrement) {
            CartHelper.incrementQuantity(product, context);
          } else {
            CartHelper.decrementQuantity(product, context);
          }
        },
      ),
    );
  }
}
