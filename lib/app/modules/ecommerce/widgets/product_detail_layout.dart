part of '../screens/ecommerce_product_detail_page.dart';

extension _ProductDetailLayout on _EcommerceProductDetailPageState {
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: CustomScrollView(
        controller: _scrollController,
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
    const double expandedHeight =
        _EcommerceProductDetailPageState._expandedAppBarHeight;

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
        child: _collapseAware(
          (shadowOpacity) => _circleButton(
            icon: Icons.arrow_back,
            onTap: () => context.pop(),
            shadowOpacity: shadowOpacity,
          ),
        ),
      ),
      actions: [
        _collapseAware(
          (shadowOpacity) => _shareButton(shadowOpacity: shadowOpacity),
        ),
        const SizedBox(width: 10),
        _collapseAware(
          (shadowOpacity) => _circleButton(
            child: FavoriteButton(product: product, size: 22),
            shadowOpacity: shadowOpacity,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _collapseAware(
            (shadowOpacity) => _cartButton(shadowOpacity: shadowOpacity),
          ),
        ),
      ],
      // The compact title lives on the app bar itself, not on
      // [FlexibleSpaceBar]. NavigationToolbar lays out leading, title and
      // actions in one row and centres them on a shared axis, so the name
      // lines up with the back and favourite buttons by construction.
      // FlexibleSpaceBar instead anchors its title to the *bottom* of the
      // flexible space via `titlePadding`, which left it sitting a few pixels
      // below the buttons and drifting with the status-bar inset.
      centerTitle: false,
      title: ValueListenableBuilder<double>(
        valueListenable: _collapseProgress,
        builder: (context, progress, _) {
          final opacity = _EcommerceProductDetailPageState._collapseHandoff(
            progress,
          );
          if (opacity <= 0) return const SizedBox.shrink();
          return Opacity(
            opacity: opacity,
            child: Text(
              product.nameMap.trLanguage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: context.textPrimary,
              ),
            ),
          );
        },
      ),
      flexibleSpace: FlexibleSpaceBar(background: _buildGallery()),
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
              _buildDiscountBadge(),
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
        // Shop products advertise the full price range their variations can
        // reach. It is fixed: picking options never changes it — the live
        // price for the current selection is the add-to-cart total.
        final (VariantPricing, VariantPricing)? range = _variationIsPrice
            ? VariantPricing.rangeOf(product, flashPrice: flashItem?.flashPrice)
            : null;
        final String shownPrice;
        final String originalPrice;
        final bool showOriginal;
        if (range != null) {
          final (low, high) = range;
          shownPrice = _formatPriceRange(low.finalPrice, high.finalPrice);
          originalPrice = _formatPriceRange(low.basePrice, high.basePrice);
          showOriginal = low.hasDiscount || high.hasDiscount;
        } else {
          shownPrice = PriceHelper.formatPrice(
            onFlashSale ? flashItem.flashPrice : product.finalPrice,
          );
          originalPrice = PriceHelper.formatPrice(product.price);
          showOriginal = onFlashSale
              ? flashItem.flashPrice < product.price
              : product.hasDiscount;
        }

        // Wrap, not Row: a range plus its struck-through original can be
        // wider than a phone, so the extras drop to the next line instead of
        // overflowing.
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 10,
          runSpacing: 4,
          children: [
            Text(
              shownPrice,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeOverLarge,
                color: ColorResource.primaryDark,
              ),
            ),
            if (showOriginal) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  originalPrice,
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: context.textLight,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
            if (onFlashSale) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: ColorResource.primaryGradient,
                    borderRadius: BorderRadius.circular(Constants.radiusLarge),
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
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth:
                            _EcommerceProductDetailPageState._maxContentWidth,
                      ),
                      child: Padding(
                        // The bar's own inset, so the gallery's left edge sits
                        // level with the logo.
                        padding: EdgeInsets.fromLTRB(
                          WebTopNav.bandInsetFor(viewport.maxWidth),
                          28,
                          WebTopNav.bandInsetFor(viewport.maxWidth),
                          32,
                        ),
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
                constraints: const BoxConstraints(
                  maxWidth: 680,
                  maxHeight: 600,
                ),
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
                                final matrix = transformationController.value
                                    .clone();
                                final currentScale = matrix.getMaxScaleOnAxis();
                                final newScale = (currentScale - 0.25).clamp(
                                  1.0,
                                  4.0,
                                );
                                setDialogState(() {
                                  transformationController.value =
                                      Matrix4.diagonal3Values(
                                        newScale,
                                        newScale,
                                        1.0,
                                      );
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            // Zoom In
                            _circleToolbarButton(
                              icon: Icons.zoom_in_rounded,
                              onTap: () {
                                final matrix = transformationController.value
                                    .clone();
                                final currentScale = matrix.getMaxScaleOnAxis();
                                final newScale = (currentScale + 0.25).clamp(
                                  1.0,
                                  4.0,
                                );
                                setDialogState(() {
                                  transformationController.value =
                                      Matrix4.diagonal3Values(
                                        newScale,
                                        newScale,
                                        1.0,
                                      );
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            // Reset Zoom
                            _circleToolbarButton(
                              icon: Icons.restart_alt_rounded,
                              onTap: () {
                                setDialogState(() {
                                  transformationController.value =
                                      Matrix4.identity();
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
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.08,
                                ),
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
                                currentIndex =
                                    (currentIndex - 1 + images.length) %
                                    images.length;
                                transformationController.value =
                                    Matrix4.identity(); // Reset zoom on image change
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
                                currentIndex =
                                    (currentIndex + 1) % images.length;
                                transformationController.value =
                                    Matrix4.identity(); // Reset zoom on image change
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

  Widget _circleToolbarButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
      child: IconButton(icon: Icon(icon, size: 20), onPressed: onTap),
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
        _buildDiscountBadge(),
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
    // Declared once and used for both the separator and the autoplay stride,
    // so a card and the step that reveals it can never disagree.
    const double cardSpacing = 14;

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
            // Steps one card at a time, desktop web only — a strip is watched
            // there and swiped everywhere else. The carousel still holds it
            // back while the pointer is over the strip and for a few beats
            // after the reader pages it themselves.
            itemExtent: cardWidth + cardSpacing,
            autoScrollInterval: isWide ? const Duration(seconds: 3) : null,
            builder: (context, carouselController) => ListView.separated(
              controller: carouselController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _suggested.length,
              // Full-bleed list: the inset lives inside the scroll view so
              // the first/last cards clear the edges while the list itself
              // spans the full section width.
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                8,
              ),
              separatorBuilder: (_, _) => const SizedBox(width: cardSpacing),
              itemBuilder: (context, index) => SizedBox(
                width: cardWidth,
                child: EcommerceProductCard(product: _suggested[index]),
              ),
            ),
          ),
      ],
    );
  }
}
