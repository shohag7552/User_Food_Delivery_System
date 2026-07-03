import 'dart:async';

import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/helper/web_search_bus.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Shared web/desktop top navigation bar.
///
/// Layout: [Brand] [Home] [Favorites] ──search── [Cart] [Orders] [Profile] [Menu]
///
/// [selectedIndex] highlights the active destination (pass null on sub-pages so
/// nothing is highlighted). Destinations map to the dashboard tab indices:
/// 0 Home · 1 Favorites · 2 Cart · 3 Orders · 4 Profile.
class WebTopNav extends StatelessWidget implements PreferredSizeWidget {
  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onMenuTap;

  const WebTopNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: ColorResource.cardBackground,
      elevation: 0.5,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.08),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool showLabels = constraints.maxWidth >= 720;
                return Padding(
                  padding: EdgeInsets.only(left: showLabels ? 20 : 12),
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        // Brand — capped so it never crowds the nav items.
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: ShaderMask(
                            shaderCallback: (bounds) => ColorResource
                                .primaryGradient
                                .createShader(bounds),
                            child: Text(
                              Constants.appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeOverLarge,
                                color: ColorResource.textWhite,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _navItem(Icons.home_rounded, 'home'.tr, 0, showLabels),
                        _navItem(
                          Icons.favorite_rounded,
                          'favorites'.tr,
                          1,
                          showLabels,
                        ),
                        // Centered live search field — typing here drives the
                        // search page (opened automatically on first input).
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 400),
                              child: const _TopNavSearchField(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _cartItem(),
                        _navItem(
                          Icons.receipt_long_rounded,
                          'orders'.tr,
                          3,
                          false,
                        ),
                        _navItem(
                          Icons.person_rounded,
                          'profile'.tr,
                          4,
                          false,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 16,
                          ),
                          child: VerticalDivider(
                            width: 1,
                            color: ColorResource.textLight
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        _menuButton(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton() {
    return Tooltip(
      message: 'menu'.tr,
      child: InkWell(
        onTap: onMenuTap,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        hoverColor: ColorResource.primaryDark.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.menu_rounded,
            size: 22,
            color: ColorResource.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, bool showLabel) {
    final isSelected = selectedIndex == index;
    final color = isSelected
        ? ColorResource.primaryDark
        : ColorResource.textSecondary;

    return Padding(
      padding: EdgeInsets.only(left: showLabel ? 8 : 2),
      child: Tooltip(
        message: showLabel ? '' : label,
        child: InkWell(
          onTap: () => onDestinationSelected(index),
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          hoverColor: ColorResource.primaryDark.withValues(alpha: 0.06),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: showLabel ? 14 : 10,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: (isSelected ? poppinsBold : poppinsMedium).copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cartItem() {
    return GetBuilder<CartController>(
      builder: (cartController) {
        final itemCount = cartController.itemCount;
        final isSelected = selectedIndex == 2;
        final color = isSelected
            ? ColorResource.primaryDark
            : ColorResource.textSecondary;

        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Tooltip(
            message: 'cart'.tr,
            child: InkWell(
              onTap: () => onDestinationSelected(2),
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              hoverColor: ColorResource.primaryDark.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.shopping_cart_rounded, color: color, size: 22),
                    if (itemCount > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: ColorResource.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              itemCount > 99 ? '99+' : '$itemCount',
                              style: poppinsBold.copyWith(
                                fontSize: 9,
                                color: ColorResource.textWhite,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Live search field in the top nav.
///
/// Backed by the app-wide [WebSearchBus] controller so the query survives
/// navigation. Typing shows a product-suggestion dropdown anchored under the
/// field (fetched live from Appwrite); pressing Enter (or a suggestion, which
/// fills the field and submits) opens the search page with the full results.
/// Clearing the field hides the suggestions and closes the search page.
class _TopNavSearchField extends StatefulWidget {
  const _TopNavSearchField();

  @override
  State<_TopNavSearchField> createState() => _TopNavSearchFieldState();
}

class _TopNavSearchFieldState extends State<_TopNavSearchField> {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _suggestionsController =
      OverlayPortalController();
  // Per-instance focus node — a single shared node breaks when two nav bars
  // are mounted at once during a route transition.
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  List<ProductModel> _suggestions = [];
  bool _loadingSuggestions = false;
  // Guards against out-of-order responses overwriting newer ones.
  int _queryEpoch = 0;

  bool get _onSearchRoute {
    final uri = AppRouter.router.routerDelegate.currentConfiguration.uri;
    return uri.path == AppRouter.search;
  }

  @override
  void initState() {
    super.initState();
    WebSearchBus.attachFocus(_focusNode);
  }

  @override
  void dispose() {
    WebSearchBus.detachFocus(_focusNode);
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    // Rebuild for the clear-button visibility.
    setState(() {});

    final query = value.trim();
    _debounce?.cancel();

    if (query.isEmpty) {
      // Cleared by typing — hide suggestions and close the search page.
      _hideSuggestions();
      _closeSearchPageIfOpen();
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _fetchSuggestions(query),
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    final epoch = ++_queryEpoch;
    setState(() => _loadingSuggestions = true);
    if (!_suggestionsController.isShowing) _suggestionsController.show();

    try {
      final results =
          await Get.find<ProductController>().searchProducts(query);
      if (!mounted || epoch != _queryEpoch) return;
      setState(() {
        _suggestions = results.take(6).toList();
        _loadingSuggestions = false;
      });
    } catch (_) {
      if (!mounted || epoch != _queryEpoch) return;
      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
      });
    }
  }

  void _hideSuggestions() {
    _queryEpoch++;
    if (_suggestionsController.isShowing) _suggestionsController.hide();
    _suggestions = [];
    _loadingSuggestions = false;
  }

  /// Submits the current (or given) query: full results on the search page.
  void _submit([String? queryOverride]) {
    _debounce?.cancel();
    if (queryOverride != null) {
      WebSearchBus.controller.text = queryOverride;
      WebSearchBus.controller.selection =
          TextSelection.collapsed(offset: queryOverride.length);
    }
    setState(_hideSuggestions);

    final query = WebSearchBus.controller.text.trim();
    if (query.isEmpty) return;

    if (WebSearchBus.isReady) {
      WebSearchBus.submit(query);
    } else if (!_onSearchRoute) {
      context.pushNamed(RouteNames.search);
    }
  }

  void _clear() {
    _debounce?.cancel();
    WebSearchBus.controller.clear();
    setState(_hideSuggestions);
    _closeSearchPageIfOpen();
  }

  void _closeSearchPageIfOpen() {
    if (_onSearchRoute) {
      AppRouter.router.pop();
    }
    // Keep typing focus after the route (and its nav bar) swaps out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WebSearchBus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _suggestionsController,
        overlayChildBuilder: _buildSuggestionsPanel,
        child: TapRegion(
          groupId: _TopNavSearchField,
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: ColorResource.scaffoldBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: ColorResource.textLight.withValues(alpha: 0.25),
              ),
            ),
            child: TextField(
              controller: WebSearchBus.controller,
              focusNode: _focusNode,
              onChanged: _handleChanged,
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.search,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'search_products'.tr,
                hintStyle: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textLight,
                ),
                isDense: true,
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: ColorResource.textSecondary,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 38,
                ),
                suffixIcon: WebSearchBus.controller.text.isNotEmpty
                    ? InkWell(
                        onTap: _clear,
                        borderRadius: BorderRadius.circular(999),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: ColorResource.textSecondary,
                        ),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 38,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Suggestion dropdown, anchored under the field. ──

  Widget _buildSuggestionsPanel(BuildContext context) {
    final width = _layerLink.leaderSize?.width ?? 400;

    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 8),
        showWhenUnlinked: false,
        child: TapRegion(
          groupId: _TopNavSearchField,
          onTapOutside: (_) => setState(_hideSuggestions),
          child: Material(
            color: ColorResource.cardBackground,
            elevation: 10,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            clipBehavior: Clip.antiAlias,
            child: _buildSuggestionsContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsContent() {
    if (_loadingSuggestions && _suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColorResource.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'searching'.tr,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 18,
              color: ColorResource.textLight,
            ),
            const SizedBox(width: 12),
            Text(
              'no_results_found'.tr,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final product in _suggestions) _suggestionTile(product),
        Divider(
          height: 1,
          color: ColorResource.textLight.withValues(alpha: 0.2),
        ),
        // Footer — run the full search for what's typed.
        InkWell(
          onTap: _submit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: ColorResource.primaryDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${'see_all_results_for'.tr} "${WebSearchBus.controller.text.trim()}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tapping a suggestion fills the field with the product name and runs the
  // full search for it (Google-style query suggestion).
  Widget _suggestionTile(ProductModel product) {
    final name = product.nameMap.trLanguage;

    return InkWell(
      onTap: () => _submit(name),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
              child: CustomNetworkImage(
                image: product.imageId,
                width: 36,
                height: 36,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              PriceHelper.formatPrice(product.finalPrice),
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
