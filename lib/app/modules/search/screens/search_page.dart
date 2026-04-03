import 'dart:async';
import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxSearchHistoryItems = 8;
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
    // Auto-focus on search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
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
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
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

  Widget _buildSearchHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 20),
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryMedium.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: ColorResource.cardBackground,
              borderRadius: BorderRadius.circular(20),
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
                color: ColorResource.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'search_for_dishes'.tr,
                hintStyle: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textLight,
                ),
                prefixIcon: IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Icons.arrow_back,
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
                            color: ColorResource.scaffoldBackground,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: ColorResource.textSecondary,
                            size: 18,
                          ),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: ColorResource.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: ColorResource.primaryDark.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: ColorResource.primaryDark.withValues(alpha: 0.25),
                    width: 1.4,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              ),
            ),
          ),
        ],
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
              color: ColorResource.textSecondary,
            ),
          ),
          if (_activeQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"$_activeQuery"',
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    final productController = Get.find<ProductController>();
    final recentProducts = productController.products.take(6).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent searches',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: ColorResource.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: Text(
                    'Clear all',
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
                    color: ColorResource.cardBackground,
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
                                color: ColorResource.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 180),
                                child: Text(
                                  item,
                                  style: poppinsRegular.copyWith(
                                    fontSize: Constants.fontSizeSmall,
                                    color: ColorResource.textPrimary,
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
                            color: ColorResource.textLight,
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
                color: ColorResource.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: recentProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  product: recentProducts[index],
                  onTap: () => ProductDetailBottomSheet.show(context, recentProducts[index]),
                );
              },
            ),
          ],
        ],
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
            Icon(
              Icons.search_off,
              size: 100,
              color: ColorResource.textLight,
            ),
            const SizedBox(height: 24),
            Text(
              'no_results_found'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeExtraLarge,
                color: ColorResource.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any dishes matching "$_activeQuery"',
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textSecondary,
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
                '${_searchResults.length} ${_searchResults.length == 1 ? 'Result' : 'Results'} Found',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: ColorResource.textPrimary,
                ),
              ),
              if (_activeQuery.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Showing matches for "$_activeQuery"',
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.textSecondary,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(
                      product: _searchResults[index],
                      onTap: () => ProductDetailBottomSheet.show(context, _searchResults[index]),
                    );
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
          color: ColorResource.cardBackground,
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
                          color: ColorResource.error,
                          borderRadius: BorderRadius.circular(Constants.radiusSmall),
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
                      color: ColorResource.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.descriptionMap.trLanguage,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${product.finalPrice.toStringAsFixed(2)}',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: ColorResource.primaryDark,
                            ),
                          ),
                          if (hasDiscount)
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: poppinsRegular.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: ColorResource.textLight,
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
