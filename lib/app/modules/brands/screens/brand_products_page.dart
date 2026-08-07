import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/web_footer.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/models/brand_model.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/widgets/ecommerce_product_card.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// All products of one brand, in a paginated grid — the brand counterpart of
/// the category products page. Mobile keeps a collapsing app bar + infinite
/// scroll; desktop web gets the shared top-nav shell with a breadcrumb, a
/// brand hero band and a wider grid.
class BrandProductsPage extends StatefulWidget {
  final BrandModel brand;

  const BrandProductsPage({super.key, required this.brand});

  @override
  State<BrandProductsPage> createState() => _BrandProductsPageState();
}

class _BrandProductsPageState extends State<BrandProductsPage> {
  static const int _pageSize = 10;
  static const double _maxContentWidth = 1100;

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
      final products = await Get.find<ProductController>().getProductsByBrand(
        widget.brand.id,
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
        _errorMessage = '${'something_went_wrong'.tr}: $e';
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
      final products = await Get.find<ProductController>().getProductsByBrand(
        widget.brand.id,
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
  // Mobile
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
            _buildSliverAppBar(),
            if (_isLoading)
              SliverFillRemaining(child: _buildLoadingState())
            else if (_errorMessage != null)
              SliverFillRemaining(child: _buildErrorState())
            else if (_products.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              _buildProductsSliver(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                spacing: 16,
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
    final crossAxisCount = width >= 1400
        ? 5
        : width >= 1100
            ? 4
            : 3;

    late final Widget contentSliver;
    if (_isLoading) {
      contentSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: _buildLoadingState(),
      );
    } else if (_errorMessage != null) {
      contentSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(),
      );
    } else if (_products.isEmpty) {
      contentSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    } else {
      contentSliver = _buildProductsSliver(
        crossAxisCount: crossAxisCount,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        spacing: 20,
      );
    }

    // Full-bleed scroll view (wheel and scrollbar work across the whole
    // screen, not just the middle column) — the content itself stays centered
    // within the cap via symmetric sliver gutters.
    final double gutter =
        width > _maxContentWidth ? (width - _maxContentWidth) / 2 : 0;

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
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: SliverToBoxAdapter(child: _buildWebHeader()),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: contentSliver,
          ),
          WebFooter.sliver(),
        ],
      ),
    );
  }

  /// Shared paginated grid; brands are ecommerce-only, so the standard
  /// [EcommerceProductCard] (with its own tap/cart/hover handling) is used.
  Widget _buildProductsSliver({
    required int crossAxisCount,
    required EdgeInsets padding,
    required double spacing,
  }) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverMasonryGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childCount: _products.length,
            itemBuilder: (context, index) => EcommerceProductCard(
              product: _products[index],
              imageAspectRatio: _imageRatioFor(index),
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

  /// Brand logo in a rounded white tile, or a storefront placeholder.
  Widget _brandLogo(double size) {
    final hasLogo = (widget.brand.logoUrl ?? '').isNotEmpty;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ColorResource.textWhite,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasLogo
          ? CustomNetworkImage(
              image: widget.brand.logoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            )
          : Icon(
              Icons.storefront_outlined,
              size: size * 0.5,
              color: ColorResource.primaryDark,
            ),
    );
  }

  Widget _buildWebHeader() {
    final description = (widget.brand.description ?? '').trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb: Home / <brand>
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
                  widget.brand.nameMap.trLanguage,
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
          // Hero band: gradient with the brand logo, name and description.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              gradient: ColorResource.primaryGradient,
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
            ),
            child: Row(
              children: [
                _brandLogo(72),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.brand.nameMap.trLanguage,
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
                            color:
                                ColorResource.textWhite.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: ColorResource.primaryDark,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: ColorResource.textWhite),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.brand.nameMap.trLanguage,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: ColorResource.primaryGradient,
              ),
            ),
            // Centered logo, faded behind the collapsing title.
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _brandLogo(64),
              ),
            ),
          ],
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
            'loading_products'.tr,
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
              _errorMessage ?? 'something_went_wrong'.tr,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                Icons.storefront_outlined,
                size: 60,
                color: context.textLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_products_found'.tr,
              style: poppinsBold.copyWith(
                fontSize: 24,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'no_brand_products_message'.tr,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
}
