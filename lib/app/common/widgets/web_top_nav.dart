import 'dart:async';

import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/localization_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/helper/web_search_bus.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/cart/widgets/web_cart_drawer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
///
/// The cart is the one exception: instead of navigating to tab 2 it slides
/// [WebCartDrawer] in from the trailing edge, so a shopper can review the cart
/// and go to checkout without losing the page they were browsing. Every other
/// destination still routes through [onDestinationSelected], and mobile — which
/// never renders this bar — is unaffected.
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

  /// Whether the web top-nav shell should be shown: the web platform at
  /// desktop width only. Mobile, tablets and narrow browser windows keep the
  /// app's regular mobile chrome (own app bars + bottom navigation).
  static bool isEnabled(BuildContext context) =>
      kIsWeb && MediaQuery.of(context).size.width >= wideBreakpoint;

  /// Width at which the app takes its desktop shape. Exposed so page bodies
  /// switch at the same width the chrome does.
  static const double wideBreakpoint = 900;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  /// Width of the bar's centred content band.
  ///
  /// Page bodies cap themselves to this so the logo and the first column of
  /// whatever is below it share a left edge. The bar's own background stays
  /// full-bleed; only its contents are held to the band.
  static const double maxContentWidth = 1200;

  /// Leading inset of the bar's contents inside [maxContentWidth].
  ///
  /// Pages must apply the same inset, not just the same cap: matching one
  /// without the other still leaves the columns and the logo a few pixels
  /// apart.
  static const double contentInset = 20;

  /// The inset used once the band is too narrow to carry labels.
  static const double _compactContentInset = 12;

  /// Below this the destinations drop their labels for icons + tooltips.
  static const double _labelBreakpoint = 1080;

  /// The bar's leading inset at a given band width.
  ///
  /// The bar tightens up when it can no longer fit its labels, so a page body
  /// that always used [contentInset] would drift 8px out of alignment in that
  /// range. Ask this instead of assuming.
  static double contentInsetFor(double bandWidth) =>
      bandWidth >= _labelBreakpoint ? contentInset : _compactContentInset;

  /// Gap between neighbouring controls inside one zone.
  static const double _itemGap = 4;

  /// Gap between zones — wide enough that the eye reads them as separate
  /// groups rather than one undifferentiated row of icons.
  static const double _groupGap = 14;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: context.cardBackground,
      elevation: 0.5,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.08),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Labels only once there is genuinely room for them. The old
                // 720 threshold was set when the bar carried fewer controls;
                // with three destinations plus language and theme it packed
                // the row solid and squeezed the search field to a stub.
                // Below this, destinations fall back to icons + tooltips.
                final bool showLabels =
                    constraints.maxWidth >= _labelBreakpoint;
                return Padding(
                  padding: EdgeInsets.only(
                    left: contentInsetFor(constraints.maxWidth),
                  ),
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
                            child: Row(
                              children: [
                                Image.asset(
                                  Images.logo,
                                  height: 28,
                                  cacheHeight: 30,
                                ),
                                const SizedBox(width: 8),

                                Text(
                                  Constants.appName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: poppinsBold.copyWith(
                                    fontSize: Constants.fontSizeOverLarge,
                                    color: ColorResource.textWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: _groupGap),

                        // ── Zone 1: destinations ──
                        // All three sit together and behave identically.
                        // Orders used to be stranded on the right with its
                        // label permanently off, which made it read as a tool
                        // rather than a place you can go.
                        _navItem(Icons.home_rounded, 'home'.tr, 0, showLabels),
                        _navItem(
                          Icons.favorite_rounded,
                          'favorites'.tr,
                          1,
                          showLabels,
                        ),
                        _navItem(
                          Icons.receipt_long_rounded,
                          'orders'.tr,
                          3,
                          showLabels,
                        ),

                        // ── Zone 2: search ──
                        // Takes the slack between the two zones; the widest
                        // single element in the bar, as the primary tool.
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: const _TopNavSearchField(),
                            ),
                          ),
                        ),

                        // ── Zone 3: preferences, then actions ──
                        const SizedBox(width: _groupGap),
                        _LanguageMenu(showLabel: showLabels),
                        _themeToggle(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _groupGap,
                            vertical: 16,
                          ),
                          child: VerticalDivider(
                            width: 1,
                            color: context.textLight.withValues(alpha: 0.25),
                          ),
                        ),
                        // Cart last but for the menu: the money action, so it
                        // gets the corner and a tinted pill rather than
                        // sitting anonymously among four other icons.
                        _cartItem(context),
                        _menuButton(),
                        const SizedBox(width: _itemGap),
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

  /// Light/dark theme switch. Rebuilds on [LocalizationController] so the icon
  /// and tooltip track the active theme; the label names the mode tapping
  /// switches *to*.
  Widget _themeToggle() {
    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        final isDark = localizationController.darkTheme;
        return Padding(
          padding: const EdgeInsets.only(left: _itemGap),
          child: Tooltip(
            message: isDark ? 'light_mode'.tr : 'dark_mode'.tr,
            child: InkWell(
              onTap: () {
                localizationController.toggleTheme();
              },
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              hoverColor: ColorResource.primaryDark.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 22,
                  color: ColorResource.textSecondary,
                ),
              ),
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.only(left: _itemGap),
      child: Tooltip(
        // Only when the label is hidden — a tooltip repeating a visible label
        // is noise, and an empty message still builds a Tooltip.
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

  Widget _cartItem(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (cartController) {
        final itemCount = cartController.itemCount;
        // Always brand-coloured: it sits on a brand tint, and unlike the
        // destinations it has no "selected" state to express — tapping it
        // opens a panel rather than navigating anywhere.
        const color = ColorResource.primaryDark;

        return Padding(
          padding: const EdgeInsets.only(left: _itemGap),
          child: Tooltip(
            message: 'cart'.tr,
            child: Material(
              // A soft brand tint, unlike every other control in the bar. The
              // cart is the one thing here that leads to a purchase, so it
              // should be findable at a glance instead of being the fifth
              // identical grey icon in a row.
              color: ColorResource.primaryDark.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              child: InkWell(
                // Opens the side panel rather than routing to the cart tab —
                // see the class doc for why the cart is the exception here.
                onTap: () => WebCartDrawer.show(context),
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
                hoverColor: ColorResource.primaryDark.withValues(alpha: 0.10),
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
      final results = await Get.find<ProductController>().searchProducts(query);
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
      WebSearchBus.controller.selection = TextSelection.collapsed(
        offset: queryOverride.length,
      );
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
              color: context.scaffoldBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                // color: context.textLight.withValues(alpha: 0.25),
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
                color: context.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'search_products'.tr,
                hintStyle: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: context.textLight,
                ),
                isDense: true,
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: context.textSecondary,
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
                          color: context.textSecondary,
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
            color: context.cardBackground,
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
                color: context.textSecondary,
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
            Icon(Icons.search_off_rounded, size: 18, color: context.textLight),
            const SizedBox(width: 12),
            Text(
              'no_results_found'.tr,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: context.textSecondary,
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
        Divider(height: 1, color: context.textLight.withValues(alpha: 0.2)),
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
                  color: context.textPrimary,
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

/// Language switcher for the web header.
///
/// A [PopupMenuButton] rather than a hand-rolled overlay: it brings correct
/// anchoring, keyboard navigation, focus handling and outside-tap dismissal
/// for free — all things a bespoke dropdown in a header tends to get wrong.
///
/// The trigger shows the active language's flag plus its code (EN / BN / AR)
/// so the current state is readable without opening anything. The code is
/// dropped on narrow windows, where the header is already tight.
class _LanguageMenu extends StatelessWidget {
  final bool showLabel;

  const _LanguageMenu({required this.showLabel});

  static const double _flagWidth = 22;
  static const double _flagHeight = 16;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        final languages = Constants.languages;

        // Derived from the live locale rather than the controller's stored
        // index, so the trigger still reads correctly if the language was
        // restored from preferences rather than picked in this session.
        final currentCode = localizationController.locale.languageCode;
        final currentIndex = languages.indexWhere(
          (l) => l.languageCode == currentCode,
        );
        final selected = languages[currentIndex < 0 ? 0 : currentIndex];

        return Tooltip(
          message: 'select_language'.tr,
          child: PopupMenuButton<int>(
            tooltip: '',
            position: PopupMenuPosition.under,
            offset: const Offset(0, 8),
            color: context.cardBackground,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              side: BorderSide(color: context.textLight.withValues(alpha: 0.2)),
            ),
            onSelected: (index) =>
                _select(localizationController, index, languages[index]),
            itemBuilder: (context) => [
              for (var i = 0; i < languages.length; i++)
                PopupMenuItem<int>(
                  value: i,
                  child: _MenuRow(
                    language: languages[i],
                    isSelected:
                        languages[i].languageCode == selected.languageCode,
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _flag(selected),
                  if (showLabel) ...[
                    const SizedBox(width: 6),
                    Text(
                      selected.languageCode.toUpperCase(),
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: ColorResource.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Mirrors the language screen's flow so both entry points behave the same:
  /// remember the index, then swap the locale (which also flips text direction
  /// for Arabic and persists the choice).
  void _select(
    LocalizationController controller,
    int index,
    LanguageModel language,
  ) {
    controller.setSelectLanguageIndex(index);
    controller.setLanguage(Locale(language.languageCode, language.countryCode));
  }

  static Widget _flag(LanguageModel language) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.asset(
        language.imageUrl,
        width: _flagWidth,
        height: _flagHeight,
        fit: BoxFit.cover,
        // Arabic ships with a placeholder world asset; any missing flag falls
        // back to a glyph rather than a broken-image box.
        errorBuilder: (context, error, _) => Icon(
          Icons.language_rounded,
          size: _flagWidth,
          color: ColorResource.textSecondary,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final LanguageModel language;
  final bool isSelected;

  const _MenuRow({required this.language, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LanguageMenu._flag(language),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            language.languageName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (isSelected ? poppinsBold : poppinsRegular).copyWith(
              fontSize: Constants.fontSizeDefault,
              color: isSelected
                  ? ColorResource.primaryDark
                  : context.textPrimary,
            ),
          ),
        ),
        if (isSelected)
          const Icon(
            Icons.check_rounded,
            size: 18,
            color: ColorResource.primaryDark,
          ),
      ],
    );
  }
}
