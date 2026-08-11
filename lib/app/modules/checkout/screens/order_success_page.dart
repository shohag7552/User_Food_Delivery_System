import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/loyalty_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/checkout/widgets/animated_success_mark.dart';
import 'package:appwrite_user_app/app/modules/checkout/widgets/confetti_burst.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
  /// Confirmation content reads like a receipt — keep it a narrow centred
  /// column on desktop web instead of stretching edge to edge.
  static const double _maxContentWidth = 480;

  /// Diameter of the success mark's filled disc. The widget sizes its own
  /// canvas around this to leave room for the ring and ripples.
  static const double _successMarkSize = 80;

  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();

  /// Mark + confetti. Separate from the content so tapping the mark can replay
  /// the celebration without the receipt fading out and back in underneath it —
  /// a replay should look like the moment happening again, not like the page
  /// reloading.
  static const Duration _celebrationDuration = Duration(milliseconds: 2200);
  static const Interval _markInterval = Interval(0, 0.46);

  /// Fires as the tick completes, so the confetti reads as its reward.
  static const Interval _confettiInterval = Interval(0.4, 1);

  /// Content rises once, on first open, and then stays put.
  static const Duration _contentDuration = Duration(milliseconds: 900);
  static const Interval _contentInterval =
      Interval(0.34, 1, curve: Curves.easeOut);

  late final AnimationController _celebrationController;
  late final AnimationController _contentController;
  late final Animation<double> _markProgress;
  late final Animation<double> _confettiProgress;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  String get orderNumber => widget.orderNumber;
  double get totalAmount => widget.totalAmount;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      vsync: this,
      duration: _celebrationDuration,
    );
    _contentController = AnimationController(
      vsync: this,
      duration: _contentDuration,
    );

    _markProgress = CurvedAnimation(
      parent: _celebrationController,
      curve: _markInterval,
    );
    _confettiProgress = CurvedAnimation(
      parent: _celebrationController,
      curve: _confettiInterval,
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: _contentInterval,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_contentFade);
  }

  /// Started here rather than in [initState] because the decision depends on
  /// MediaQuery. With reduce-motion on, both controllers are jumped to their
  /// end value so everything renders its final frame and nothing ever moves.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_celebrationController.status != AnimationStatus.dismissed) return;

    if (MediaQuery.disableAnimationsOf(context)) {
      _celebrationController.value = 1;
      _contentController.value = 1;
    } else {
      _celebrationController.forward();
      _contentController.forward();
    }
  }

  /// Replays the mark and confetti on demand. Ignored under reduce-motion —
  /// an explicit tap does not override an accessibility preference.
  void _replayCelebration() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _celebrationController.forward(from: 0);
  }

  Future<void> _copyOrderNumber() async {
    await Clipboard.setData(ClipboardData(text: orderNumber));
    if (!mounted) return;
    customToster('order_number_copied'.tr, isSuccess: true);
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _goToOrders() => context.goNamed(RouteNames.orders);

  void _goHome() => context.goNamed(RouteNames.dashboard);

  @override
  Widget build(BuildContext context) {
    final useWebShell = WebTopNav.isEnabled(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // On mobile this page has no AppBar, and an AppBar is what normally
    // publishes a status-bar style. Without one the bar keeps whatever the
    // previous route set — arriving from checkout's dark app bar, that means
    // light icons sitting on this page's light background, i.e. an invisible
    // clock and battery.
    //
    // AnnotatedRegion is scoped to this route, so the style reverts on its own
    // when the page is left, unlike the imperative SystemChrome call in
    // Global.setSystemUi.
    final statusBarStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Android names this after the ICONS…
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      // …while iOS names the same idea after the BACKGROUND behind them, so
      // the two values are always inverses of each other. Setting only one is
      // the usual reason this looks right on one platform and not the other.
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

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
      // The confetti sits above the content as a full-bleed overlay so pieces
      // can travel past the receipt and off the edges of the screen. It never
      // takes pointer events, so the buttons underneath stay usable while it
      // is still falling.
      body: Stack(
        children: [
          SafeArea(
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
                      Center(child: _buildTappableMark()),
                      const SizedBox(height: Constants.paddingSizeSmall),
                      FadeTransition(
                        opacity: _contentFade,
                        child: SlideTransition(
                          position: _contentSlide,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeadline(),
                              const SizedBox(
                                height: Constants.paddingSizeLarge,
                              ),
                              _buildOrderNumberCard(),
                              _buildLoyaltyEarning(),
                              const SizedBox(
                                height: Constants.paddingSizeDefault,
                              ),
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
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiBurst(
                progress: _confettiProgress,
                // Roughly where the success mark sits, so the burst reads as
                // coming from behind it rather than from the top of the page.
                origin: const Offset(0.5, 0.26),
              ),
            ),
          ),
        ],
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: statusBarStyle,
        child: scaffold,
      ),
    );
  }

  /// The mark doubles as a replay button. Deliberately undecorated — no ring,
  /// no ripple hint — because it must still read as a status icon first; the
  /// tooltip and the long-press label carry the affordance for anyone looking
  /// for it.
  Widget _buildTappableMark() {
    return Semantics(
      button: true,
      label: 'tap_to_replay'.tr,
      child: Tooltip(
        message: 'tap_to_replay'.tr,
        child: GestureDetector(
          onTap: _replayCelebration,
          behavior: HitTestBehavior.opaque,
          child: AnimatedSuccessMark(
            progress: _markProgress,
            size: _successMarkSize,
          ),
        ),
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
  /// Sized to the number rather than stretched across the column. A full-width
  /// card holding one short centred value leaves a lot of empty panel around a
  /// little bit of text, which is what made this section feel unsettled — a
  /// pill that hugs its contents sits still.
  ///
  /// Tapping copies. That is the one thing people do with an order number, and
  /// it also gives the container a job, so it reads as a control rather than
  /// decoration around a value.
  Widget _buildOrderNumberCard() {
    final borderRadius = BorderRadius.circular(Constants.radiusExtraLarge);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: ColorResource.primaryDark.withValues(alpha: 0.07),
          borderRadius: borderRadius,
          child: InkWell(
            onTap: _copyOrderNumber,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Constants.paddingSizeLarge,
                vertical: Constants.paddingSizeSmall + 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '#$orderNumber',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeOverLarge,
                        color: ColorResource.primaryDark,
                        // Enough to separate the digits, not so much that the
                        // number stops reading as one token.
                        letterSpacing: 0.8,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: Constants.paddingSizeSmall),
                  Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: ColorResource.primaryDark.withValues(alpha: 0.65),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
