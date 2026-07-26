import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/web_footer.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/coupon_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/modules/coupons/screens/coupon_details_screen.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class CouponsScreen extends StatefulWidget {
  final bool isSelectionMode;
  final Function(CouponModel)? onCouponSelected;

  const CouponsScreen({
    super.key,
    this.isSelectionMode = false,
    this.onCouponSelected,
  });

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final CouponController _controller = Get.find<CouponController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Caps the grid width on desktop web so cards stay readable.
  static const double _maxContentWidth = 1000;

  /// At or above this inner width the web grid shows two columns.
  static const double _twoColumnWidth = 680;

  @override
  void initState() {
    super.initState();
    _controller.getCoupons();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWeb = WebTopNav.isEnabled(context);
    // Selection mode is a focused picker (pushed from checkout), so it keeps its
    // own app bar rather than the full web shell.
    final showWebNav = isWeb && !widget.isSelectionMode;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: showWebNav
          ? WebTopNav(
              selectedIndex: null,
              onDestinationSelected: (index) =>
                  DashboardTabs.open(context, index),
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            )
          : CustomAppbar(
              title: widget.isSelectionMode ? 'select_coupon'.tr : 'coupons'.tr,
            ),
      endDrawer: showWebNav ? const WebProfileDrawer() : null,
      body: AuthGate(
        child: GetBuilder<CouponController>(
        builder: (controller) {
          if (controller.isLoading && controller.coupons == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.coupons == null || controller.coupons!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_rounded,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_coupons_yet'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'tap_to_add_coupon'.tr,
                    style: poppinsRegular.copyWith(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildCouponsList(context, controller, isWeb, showWebNav);
        },
        ),
      ),
    );
  }

  /// The coupons list. Mobile is a single-column list; web is a responsive
  /// card grid on a full-width scroll surface (drag anywhere to scroll), centred
  /// within [_maxContentWidth], with an inline title (unless it's the selection
  /// picker, which carries its own app-bar title).
  Widget _buildCouponsList(
    BuildContext context,
    CouponController controller,
    bool isWeb,
    bool showInlineTitle,
  ) {
    final coupons = controller.coupons!;

    if (!isWeb) {
      return RefreshIndicator(
        onRefresh: () => controller.getCoupons(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: coupons.length,
          itemBuilder: (context, index) {
            return _CouponCard(
              coupon: coupons[index],
              isSelectionMode: widget.isSelectionMode,
              onSelect: widget.onCouponSelected,
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.getCoupons(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showInlineTitle) ...[
                    Text(
                      'coupons'.tr,
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeOverLarge,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = width >= _twoColumnWidth ? 2 : 1;
                      const spacing = 16.0;
                      final itemWidth =
                          (width - (columns - 1) * spacing) / columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: 0, // cards carry their own bottom margin
                        children: [
                          for (final coupon in coupons)
                            SizedBox(
                              width: itemWidth,
                              child: _CouponCard(
                                coupon: coupon,
                                isSelectionMode: widget.isSelectionMode,
                                onSelect: widget.onCouponSelected,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const WebFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final bool isSelectionMode;
  final Function(CouponModel)? onSelect;

  const _CouponCard({
    required this.coupon,
    this.isSelectionMode = false,
    this.onSelect,
  });

  void _copyCouponCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: coupon.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'coupon_code_copied'.tr,
          style: poppinsMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    // Web: show the details in a centred dialog instead of a pushed page.
    if (WebTopNav.isEnabled(context)) {
      showCouponDetailsDialog(
        context,
        coupon: coupon,
        isSelectionMode: isSelectionMode,
        onSelect: onSelect,
      );
      return;
    }
    context.pushNamed(
      RouteNames.couponDetails,
      pathParameters: {'id': coupon.id ?? ''},
      extra: CouponDetailsArgs(
        coupon: coupon,
        isSelectionMode: isSelectionMode,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isExpired = now.isAfter(coupon.validUntil);
    final isNotYetValid = now.isBefore(coupon.validFrom);
    final isUsageLimitReached =
        coupon.usageLimit != null && coupon.usedCount >= coupon.usageLimit!;
    final isUnavailable =
        !coupon.isActive || isExpired || isNotYetValid || isUsageLimitReached;
    final backgroundGradientColors = isUnavailable
        ? [
            theme.cardColor,
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.94),
          ]
        : [
            const Color(0xFFFFFDF9),
            const Color(0xFFF7F1E8),
            const Color(0xFFFBF7F0),
          ];
    final titleColor = isUnavailable
        ? theme.textTheme.titleMedium?.color?.withValues(alpha: 0.68)
        : theme.textTheme.titleMedium?.color;
    final bodyColor = isUnavailable
        ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.62)
        : theme.textTheme.bodyMedium?.color;
    final accentColor = isUnavailable
        ? theme.disabledColor
        : const Color(0xFF8F2D2D);
    final highlightColor = isUnavailable
        ? theme.dividerColor.withValues(alpha: 0.16)
        : const Color(0xFFD9C6B3).withValues(alpha: 0.34);

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isUnavailable
                  ? theme.shadowColor.withValues(alpha: 0.05)
                  : const Color(0xFF3F2D1F).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(
            color: isUnavailable
                ? theme.dividerColor.withValues(alpha: 0.9)
                : const Color(0xFFD8CABB),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: backgroundGradientColors,
                  ),
                ),
              ),
              Positioned(
                top: -34,
                right: -28,
                child: Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: highlightColor,
                  ),
                ),
              ),
              Positioned(
                bottom: -42,
                left: -20,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: accentColor.withValues(alpha: 0.9),
                      width: 4,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.08),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.12),
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              coupon.code,
                              style: poppinsMedium.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            coupon.description,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: titleColor ?? context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: coupon.discountDisplay,
                                  style: poppinsBold.copyWith(
                                    fontSize: 24,
                                    color: accentColor,
                                  ),
                                ),
                                TextSpan(
                                  text: ' OFF',
                                  style: poppinsMedium.copyWith(
                                    fontSize: Constants.fontSizeDefault,
                                    color:
                                        bodyColor ??
                                        context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: bodyColor?.withValues(alpha: 0.82),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${'valid_till'.tr} ${_formatDate(coupon.validUntil)}',
                                  style: poppinsRegular.copyWith(
                                    fontSize: Constants.fontSizeSmall,
                                    color:
                                        bodyColor ??
                                        context.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      height: 42,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _copyCouponCode(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: isUnavailable
                              ? accentColor.withValues(alpha: 0.12)
                              : const Color(0xFFF3E6DA),
                          foregroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: Text(
                          'Copy',
                          style: poppinsMedium.copyWith(
                            fontSize: Constants.fontSizeSmall,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 86,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPerforation(theme),
                    _buildPerforation(theme),
                    _buildPerforation(theme),
                    _buildPerforation(theme),
                    _buildPerforation(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerforation(ThemeData theme) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        shape: BoxShape.circle,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
