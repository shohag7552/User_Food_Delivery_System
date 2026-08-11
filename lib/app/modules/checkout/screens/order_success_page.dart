import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/loyalty_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Order confirmation.
///
/// One unmistakable success mark, the order number, then the way onward. The
/// brand colour is spent on the order number and the primary action only;
/// everything else stays quiet so the number is the thing you look at.
///
/// [totalAmount] is not displayed — the customer has just seen it on the
/// checkout screen, and the full breakdown lives on the order detail page. It
/// is still needed here to work out the loyalty points this order will earn.
class OrderSuccessPage extends StatefulWidget {
  final String orderNumber;
  final double totalAmount;

  const OrderSuccessPage({
    super.key,
    required this.orderNumber,
    required this.totalAmount,
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage>
    with SingleTickerProviderStateMixin {
  /// Confirmation content reads like a receipt — keep it a narrow centred
  /// column on desktop web instead of stretching edge to edge.
  static const double _maxContentWidth = 480;

  /// Diameter of the success mark, and of the soft glow behind it.
  static const double _successMarkSize = 96;
  static const double _glowSize = 220;

  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();

  late final AnimationController _animationController;
  late final Animation<double> _markScale;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  String get orderNumber => widget.orderNumber;
  double get totalAmount => widget.totalAmount;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // The mark lands first with a slight overshoot, then the receipt rises
    // under it — a short sequence reads as one confirmation, where fading
    // everything at once reads as a page that was simply slow to paint.
    _markScale = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
    );
    _contentFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_contentFade);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _goToOrders() => context.goNamed(RouteNames.orders);

  void _goHome() => context.goNamed(RouteNames.dashboard);

  @override
  Widget build(BuildContext context) {
    final useWebShell = WebTopNav.isEnabled(context);

    final scaffold = Scaffold(
      key: _webScaffoldKey,
      backgroundColor: context.scaffoldBackground,
      endDrawer: useWebShell ? const WebProfileDrawer() : null,
      appBar: useWebShell
          ? WebTopNav(
              selectedIndex: null,
              onDestinationSelected: (index) => DashboardTabs.open(context, index),
              onMenuTap: () => _webScaffoldKey.currentState?.openEndDrawer(),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeLarge,
              vertical: Constants.paddingSizeExtraLarge,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSuccessMark(),
                  const SizedBox(height: Constants.paddingSizeExtraLarge),
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeadline(),
                          const SizedBox(height: Constants.paddingSizeExtraLarge),
                          _buildOrderNumberCard(),
                          _buildLoyaltyEarning(),
                          const SizedBox(height: Constants.paddingSizeDefault),
                          _buildTrackHint(),
                          const SizedBox(height: Constants.spaceSection),
                          _buildActions(),
                        ],
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

    // Returning to checkout after a successful order would invite a duplicate
    // submission, so back is blocked. On mobile it is redirected home rather
    // than doing nothing, which otherwise reads as a frozen app. On web the
    // browser drives history through go_router and PopScope does not apply.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || kIsWeb) return;
        _goHome();
      },
      child: scaffold,
    );
  }

  /// Success mark: a filled brand-green disc on a soft glow of the same hue.
  ///
  /// Scaled in rather than cross-faded — the overshoot is what makes it read as
  /// a stamp landing. Honours the platform's "reduce motion" setting, where the
  /// controller is left at its end value instead.
  Widget _buildSuccessMark() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final mark = Container(
      width: _successMarkSize,
      height: _successMarkSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorResource.success,
        boxShadow: [
          BoxShadow(
            color: ColorResource.success.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 52,
        color: ColorResource.textWhite,
      ),
    );

    return SizedBox(
      height: _glowSize * 0.62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient glow, drawn behind and clipped by nothing — it fades to
          // transparent so it sits on either theme's ground without a seam.
          IgnorePointer(
            child: Container(
              width: _glowSize,
              height: _glowSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ColorResource.success.withValues(alpha: 0.16),
                    ColorResource.success.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          if (reduceMotion) mark else ScaleTransition(scale: _markScale, child: mark),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return Column(
      children: [
        Text(
          'order_placed_successfully'.tr,
          textAlign: TextAlign.center,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeOverLarge,
            color: context.textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeSmall),
        Text(
          'thank_you_for_your_order'.tr,
          textAlign: TextAlign.center,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// The one thing worth keeping from this screen.
  ///
  /// A single value gets a single-purpose panel rather than a label/value row:
  /// with nothing to align against, a two-column layout just pushes the number
  /// to an edge. Centred and stacked, the number is the largest thing on the
  /// card and reads at a glance — which is what people do with it, quoting it
  /// back when they contact support.
  Widget _buildOrderNumberCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Constants.paddingSizeDefault,
        vertical: Constants.paddingSizeLarge,
      ),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
        // Brand-tinted edge rather than a neutral hairline: this panel is the
        // page's reference number, not just another surface.
        border: Border.all(
          color: ColorResource.primaryDark.withValues(alpha: 0.22),
        ),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'order_number'.tr.toUpperCase(),
            textAlign: TextAlign.center,
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeExtraSmall,
              color: context.textSecondary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: Constants.paddingSizeSmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '#$orderNumber',
              maxLines: 1,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeOverLarge,
                color: ColorResource.primaryDark,
                letterSpacing: 1.5,
                // Even glyph widths — the number is read digit by digit.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "You'll earn N points" — only when the store is actually running the
  /// loyalty programme.
  ///
  /// Points are awarded by the store app when the order reaches `delivered`,
  /// not now, so the copy promises a future credit rather than implying the
  /// balance has already moved. [LoyaltyController.pointsForOrderTotal] mirrors
  /// the store's award arithmetic, and returns 0 when the programme is off or
  /// the rate rounds the order down to nothing — either way the row is hidden
  /// instead of showing "0 points".
  Widget _buildLoyaltyEarning() {
    if (!Get.isRegistered<LoyaltyController>()) return const SizedBox.shrink();

    return GetBuilder<LoyaltyController>(
      builder: (loyaltyController) {
        final points = loyaltyController.pointsForOrderTotal(totalAmount);
        if (points <= 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: Constants.paddingSizeDefault),
          padding: const EdgeInsets.all(Constants.paddingSizeDefault),
          decoration: BoxDecoration(
            color: ColorResource.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            border: Border.all(
              color: ColorResource.success.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: Constants.minTapTarget,
                height: Constants.minTapTarget,
                decoration: BoxDecoration(
                  color: ColorResource.success,
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: ColorResource.textWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: Constants.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'loyalty_points_count'.trParams({'points': '$points'}),
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'loyalty_points_earn_on_delivery'.tr,
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// One quiet line telling the customer where this order lives from now on.
  /// Deliberately module-agnostic — food and ecommerce orders move through
  /// different status vocabularies, so promising specific next steps here would
  /// be wrong for one of them.
  Widget _buildTrackHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: context.textLight,
        ),
        const SizedBox(width: Constants.paddingSizeExtraSmall + 1),
        Flexible(
          child: Text(
            'track_order_hint'.tr,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: context.textLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: Constants.minTapTarget + Constants.paddingSizeDefault,
          child: ElevatedButton.icon(
            onPressed: _goToOrders,
            icon: const Icon(Icons.receipt_long_rounded, size: 20),
            label: Text(
              'view_my_orders'.tr,
              style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.primaryDark,
              foregroundColor: ColorResource.textWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
            ),
          ),
        ),
        const SizedBox(height: Constants.paddingSizeSmall),
        SizedBox(
          height: Constants.minTapTarget + Constants.paddingSizeDefault,
          child: TextButton.icon(
            onPressed: _goHome,
            icon: const Icon(Icons.storefront_outlined, size: 20),
            label: Text(
              'continue_shopping'.tr,
              style: poppinsMedium.copyWith(fontSize: Constants.fontSizeDefault),
            ),
            style: TextButton.styleFrom(
              // Secondary action, so it carries no fill and no border — the
              // previous outlined button used a hardcoded white background that
              // sat as a bright slab on the dark theme.
              foregroundColor: context.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
