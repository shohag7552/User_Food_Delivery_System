import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class OrderFailedPage extends StatefulWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const OrderFailedPage({
    super.key,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  State<OrderFailedPage> createState() => _OrderFailedPageState();
}

class _OrderFailedPageState extends State<OrderFailedPage> {
  /// Error content reads like a dialog — keep it a narrow centered column on
  /// desktop web instead of stretching edge to edge.
  static const double _maxContentWidth = 480;
  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();

  String get errorMessage => widget.errorMessage;
  VoidCallback? get onRetry => widget.onRetry;

  @override
  Widget build(BuildContext context) {
    final useWebShell = WebTopNav.isEnabled(context);

    return PopScope(
      canPop: true,
      child: Scaffold(
        key: _webScaffoldKey,
        backgroundColor: ColorResource.scaffoldBackground,
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
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Error Animation
                    _buildErrorAnimation(),
                    const SizedBox(height: 32),

                    // Error Message
                    Text(
                      'order_failed'.tr,
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeExtraLarge + 4,
                        color: ColorResource.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'could_not_process_order'.tr,
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Error Details Card
                    _buildErrorDetailsCard(),
                    const SizedBox(height: 40),

                    // Action Buttons
                    _buildActionButtons(context),
                  ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorAnimation() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.red.shade400,
            Colors.red.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade200,
            blurRadius: 30,
            spreadRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.error_outline,
        size: 100,
        color: ColorResource.textWhite,
      ),
    );
  }

  Widget _buildErrorDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 40,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'error_details'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Retry Button
        if (onRetry != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.pop(); // Go back to checkout
                onRetry?.call(); // Trigger retry
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                'try_again'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                foregroundColor: ColorResource.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusLarge),
                ),
              ),
            ),
          ),
        if (onRetry != null) const SizedBox(height: 16),

        // Go Back Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.pop(); // Go back to checkout
            },
            icon: const Icon(Icons.arrow_back),
            label: Text(
              'go_back_to_checkout'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorResource.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: ColorResource.textSecondary,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Home Button
        TextButton.icon(
          onPressed: () {
            context.goNamed(RouteNames.dashboard); // Go to home
          },
          icon: const Icon(Icons.home_outlined),
          label: Text(
            'go_to_home'.tr,
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeDefault,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: ColorResource.primaryDark,
          ),
        ),
      ],
    );
  }
}
