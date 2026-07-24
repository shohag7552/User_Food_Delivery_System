import 'dart:async';
import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/helper/web_search_bus.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:appwrite_user_app/app/common/widgets/directional_flip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxSearchHistoryItems = 8;

  // Web/desktop layout kicks in above this width.
  static const double _webBreakpoint = 900;
  static const double _maxContentWidth = 1100;
  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _webScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  List<ProductModel> _searchResults = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();

    if (kIsWeb) {
      // The top-nav field owns the query on web — listen for what's typed
      // there and adopt any text entered before this page opened.
      WebSearchBus.register(_handleWebQuery);
      final pendingQuery = WebSearchBus.controller.text;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WebSearchBus.requestFocus();
        if (pendingQuery.trim().isNotEmpty) {
          _handleWebQuery(pendingQuery);
        }
      });
    } else {
      // Auto-focus on search field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (kIsWeb) WebSearchBus.clear(_handleWebQuery);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _webScrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Query submitted from the web top-nav search field.
  void _handleWebQuery(String query) {
    // Defensive: never act on a stale call after this page is disposed.
    if (!mounted) return;
    _searchController.text = query;
    _onSearchChanged(query);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isSearching = false;
        _activeQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _activeQuery = normalizedQuery;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(normalizedQuery);
    });
  }

  Future<void> _loadSearchHistory() async {
    final sharedPreferences = Get.find<SharedPreferences>();
    final searchHistory = sharedPreferences.getStringList(_searchHistoryKey) ?? [];

    if (!mounted) {
      return;
    }

    setState(() {
      _searchHistory = searchHistory;
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return;
    }

    final updatedHistory = [normalizedQuery, ..._searchHistory.where((item) => item.toLowerCase() != normalizedQuery.toLowerCase())]
        .take(_maxSearchHistoryItems)
        .toList();
    final sharedPreferences = Get.find<SharedPreferences>();
    await sharedPreferences.setStringList(_searchHistoryKey, updatedHistory);

    if (!mounted) {
      return;
    }

    setState(() {
      _searchHistory = updatedHistory;
    });
  }

  Future<void> _removeHistoryItem(String query) async {
    final updatedHistory = _searchHistory.where((item) => item != query).toList();
    final sharedPreferences = Get.find<SharedPreferences>();
    await sharedPreferences.setStringList(_searchHistoryKey, updatedHistory);

    if (!mounted) {
      return;
    }

    setState(() {
      _searchHistory = updatedHistory;
    });
  }

  Future<void> _clearSearchHistory() async {
    final sharedPreferences = Get.find<SharedPreferences>();
    await sharedPreferences.remove(_searchHistoryKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _searchHistory = [];
    });
  }

  void _searchFromHistory(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(TextPosition(offset: query.length));
    _onSearchChanged(query);
    _searchFocusNode.unfocus();
  }

  void _performSearch(String query) async {
    try {
      final productController = Get.find<ProductController>();
      final results = await productController.searchProducts(query);

      if (mounted && _activeQuery == query) {
        await _saveSearchHistory(query);
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted && _activeQuery == query) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _hasSearched = true;
        });
      }
    }
  }

  void _clearSearch() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
      _isSearching = false;
      _activeQuery = '';
    });
    if (kIsWeb) {
      WebSearchBus.controller.clear();
      WebSearchBus.requestFocus();
    } else {
      _searchFocusNode.requestFocus();
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
      body: Column(
        children: [
          // Search Header
          _buildSearchHeader(),

          // Search Results
          Expanded(
            child: _buildSearchBody(),
          ),
        ],
      ),
    );
  }

  // ── Web/desktop: shared top-nav + centered, width-capped content. ──
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
      // One scroll view for the whole page (the top-nav search field drives
      // the query on web — no in-page search box).
      body: _buildWebBody(),
    );
  }

  Widget _buildWebBody() {
    Widget content;
    if (_isSearching) {
      content = SizedBox(height: 420, child: _buildLoadingState());
    } else if (!_hasSearched) {
      content = _buildInitialContent();
    } else if (_searchResults.isEmpty) {
      content = SizedBox(height: 480, child: _buildEmptyState());
    } else {
      content = _buildWebResults();
    }

    return Scrollbar(
      controller: _webScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _webScrollController,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  // Results header + grid laid out inline so the whole page scrolls together.
  Widget _buildWebResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${_searchResults.length} ',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeOverLarge,
                  color: ColorResource.primaryDark,
                ),
              ),
              TextSpan(
                text: 'results_found'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeExtraLarge,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (_activeQuery.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${'showing_matches_for'.tr} "$_activeQuery"',
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridCrossAxisCount(),
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return _buildResultCard(_searchResults[index]);
          },
        ),
      ],
    );
  }

  /// Responsive grid column count — 2 on phones, up to 5 on wide desktop.
  int _gridCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 5;
    if (width >= 1100) return 4;
    if (width >= _webBreakpoint) return 3;
    return 2;
  }

  /// Product card, lifted on hover for web (pointer-only, no effect on touch).
  Widget _buildResultCard(ProductModel product) {
    final card = _buildProductCard(
      product: product,
      onTap: () => _openProduct(product),
    );
    return kIsWeb ? HoverLift(child: card) : card;
  }

  /// Ecommerce items open their full detail page; food items keep the
  /// quick-view bottom sheet.
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

  Widget _buildSearchHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(Constants.paddingSizeDefault, topPadding + 5, Constants.paddingSizeDefault, Constants.paddingSizeSmall),
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onSearchChanged,
          onSubmitted: (value) => _onSearchChanged(value),
          textInputAction: TextInputAction.search,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'search_for_dishes'.tr,
            hintStyle: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textLight,
            ),
            prefixIcon: IconButton(
              onPressed: () => context.pop(),
              icon: const DirectionalFlip(
                child: Icon(Icons.arrow_back),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minHeight: 42,
                minWidth: 42,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minHeight: 24,
              minWidth: 44,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: _clearSearch,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.scaffoldBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: context.textSecondary,
                        size: 18,
                      ),
                    ),
                  )
                : null,
            filled: true,
            fillColor: context.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: ColorResource.primaryDark.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: ColorResource.primaryDark.withValues(alpha: 0.25),
                width: 1.4,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBody() {
    if (_isSearching) {
      return _buildLoadingState();
    }

    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSearchResults();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ColorResource.primaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            'searching'.tr,
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textSecondary,
            ),
          ),
          if (_activeQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"$_activeQuery"',
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: context.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: _buildInitialContent(),
    );
  }

  Widget _buildInitialContent() {
    final productController = Get.find<ProductController>();
    final recentProducts = productController.products.take(6).toList();

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'recent_searches'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: context.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: Text(
                    'clear_all'.tr,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _searchHistory.map((item) {
                return Container(
                  decoration: BoxDecoration(
                    color: context.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ColorResource.primaryDark.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _searchFromHistory(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 16,
                                color: context.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 180),
                                child: Text(
                                  item,
                                  style: poppinsRegular.copyWith(
                                    fontSize: Constants.fontSizeSmall,
                                    color: context.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _removeHistoryItem(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(2, 10, 12, 10),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: context.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          if (recentProducts.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'popular_items'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridCrossAxisCount(),
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: recentProducts.length,
              itemBuilder: (context, index) {
                return _buildResultCard(recentProducts[index]);
              },
            ),
          ],
        ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 100,
              color: context.textLight,
            ),
            const SizedBox(height: 24),
            Text(
              'no_results_found'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeExtraLarge,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${'no_matches_for_query'.tr} "$_activeQuery"',
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                foregroundColor: ColorResource.textWhite,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusLarge),
                ),
              ),
              child: Text(
                  'try_another_search'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_searchResults.length} ${'results_found'.tr}',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: context.textPrimary,
                ),
              ),
              if (_activeQuery.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${'showing_matches_for'.tr} "$_activeQuery"',
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? const SizedBox()
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridCrossAxisCount(),
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return _buildResultCard(_searchResults[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard({
    required ProductModel product,
    required VoidCallback onTap,
  }) {
    final hasDiscount = product.hasDiscount;
    final discountPercentage = hasDiscount
        ? ((product.price - product.finalPrice) / product.price * 100).toStringAsFixed(0)
        : null;

    return CustomClickableWidget(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          boxShadow: ColorResource.customShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(Constants.radiusLarge),
                      topRight: Radius.circular(Constants.radiusLarge),
                    ),
                    child: CustomNetworkImage(
                      image: product.imageId,
                      height: 160,
                      width: double.infinity,
                    ),
                  ),
                  // Discount Badge
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorResource.discountBadge,
                          borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
                        ),
                        child: Text(
                          '$discountPercentage% OFF',
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeExtraSmall,
                            color: ColorResource.textWhite,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nameMap.trLanguage,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),
                  RatingStars(
                    rating: product.avgRating,
                    reviewCount: product.ratingCount,
                    size: 14,
                  ),
                  // const SizedBox(height: 4),
                  // Text(
                  //   product.descriptionMap.trLanguage,
                  //   style: poppinsRegular.copyWith(
                  //     fontSize: Constants.fontSizeSmall,
                  //     color: context.textSecondary,
                  //   ),
                  //   maxLines: 2,
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            PriceHelper.formatPrice(product.finalPrice),
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: ColorResource.primaryDark,
                            ),
                          ),
                          if (hasDiscount)
                            Text(
                              PriceHelper.formatPrice(product.price),
                              style: poppinsRegular.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: context.textLight,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: ColorResource.primaryGradient,
                          borderRadius: BorderRadius.circular(Constants.radiusDefault),
                          boxShadow: [
                            BoxShadow(
                              color: ColorResource.primaryMedium.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_shopping_cart,
                          color: ColorResource.textWhite,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
