import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

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

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  /// Confirmation content reads like a receipt — keep it a narrow centered
  /// column on desktop web instead of stretching edge to edge.
  static const double _maxContentWidth = 520;
  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();

  String get orderNumber => widget.orderNumber;
  double get totalAmount => widget.totalAmount;

  @override
  Widget build(BuildContext context) {
    final useWebShell = WebTopNav.isEnabled(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        key: _webScaffoldKey,
        backgroundColor: context.scaffoldBackground,
        endDrawer: useWebShell ? const WebProfileDrawer() : null,
        appBar: useWebShell
            ? WebTopNav(
                selectedIndex: null,
                onDestinationSelected: (index) {
                  DashboardTabs.open(context, index);
                },
                onMenuTap: () => _webScaffoldKey.currentState?.openEndDrawer(),
              )
            : null,
        body: Padding(
          // Mobile offsets the gradient band below the status bar; on web the
          // top nav already provides the chrome.
          padding: EdgeInsets.only(top: useWebShell ? 0 : 40),
          child: Stack(
            children: [
              Container(
                height: 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ColorResource.primaryDark,
                      ColorResource.primaryMedium,
                      context.scaffoldBackground,
                    ],
                    stops: const [0, 0.65, 1],
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, useWebShell ? 32 : 20, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: _maxContentWidth),
                    child: Column(
                      children: [
                        _buildTopBadge(),
                        const SizedBox(height: 50),
                        _buildHeroCard(),
                        // const SizedBox(height: 18),
                        // _buildOrderDetailsCard(),
                        // const SizedBox(height: 18),
                        // _buildStatusCard(),
                        const SizedBox(height: 28),
                        _buildActionButtons(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment & order confirmed',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessAnimation() {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorResource.success.withValues(alpha: 0.12),
        border: Border.all(
          color: ColorResource.success.withValues(alpha: 0.18),
          width: 10,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorResource.success.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: ColorResource.success,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 52,
          color: ColorResource.textWhite,
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryDark.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSuccessAnimation(),
          const SizedBox(height: 22),
          Text(
            'order_placed_successfully'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeOverLarge + 4,
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'thank_you_for_your_order'.tr,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.scaffoldBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  'order_number'.tr,
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '#$orderNumber',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeExtraLarge + 2,
                    color: ColorResource.primaryDark,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order summary',
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            icon: Icons.payments_outlined,
            label: 'Amount paid',
            value: CurrencyHelper.formatWithSeparators(totalAmount),
            valueColor: ColorResource.primaryDark,
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.schedule_rounded,
            label: 'Estimated status',
            value: 'Preparing your order',
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorResource.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ColorResource.success.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ColorResource.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What happens next?',
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can track progress from your orders page once the restaurant starts preparing it.',
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: context.textSecondary,
                          height: 1.45,
                        ),
                      ),
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

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            ColorResource.primaryLight.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ColorResource.primaryDark.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: ColorResource.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your receipt is ready',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review order details, payment, and delivery updates anytime from My Orders.',
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: context.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ColorResource.primaryDark.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: ColorResource.primaryDark,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: context.textSecondary,
                ),
              ),
              Text(
                value,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: valueColor ?? context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Replace with the orders page so the success page is removed from the stack
              context.goNamed(RouteNames.orders);
            },
            icon: const Icon(Icons.receipt_long),
            label: Text(
              'view_my_orders'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.primaryDark,
              foregroundColor: ColorResource.textWhite,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Go back to home/dashboard, clear navigation stack
              context.goNamed(RouteNames.dashboard);
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(
              'continue_shopping'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorResource.primaryDark,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 17),
              side: BorderSide(
                color: ColorResource.primaryDark.withValues(alpha: 0.22),
                width: 1.4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
