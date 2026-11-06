import 'package:kikomart_user_app/app/common/widgets/auth_gate.dart';
import 'package:kikomart_user_app/app/common/widgets/web_footer.dart';
import 'package:kikomart_user_app/app/common/widgets/web_top_nav.dart';
import 'package:kikomart_user_app/app/controllers/profile_controller.dart';
import 'package:kikomart_user_app/app/controllers/wallet_controller.dart';
import 'package:kikomart_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:kikomart_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:kikomart_user_app/app/modules/wallet/widgets/wallet_balance_card.dart';
import 'package:kikomart_user_app/app/modules/wallet/widgets/wallet_transaction_tile.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The customer's wallet: balance on top, then every change to it.
///
/// Laid out like the Loyalty Points page: on web the balance card and the
/// history sit side by side inside the top nav's content band; on mobile they
/// stack. History pages in on scroll (mobile) or with "View more" (web).
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();

  // Web loads the next page with "View more", so scroll loading is mobile-only.
  bool _isWeb = false;

  @override
  void initState() {
    super.initState();
    // After the first frame: loading refreshes ProfileController, whose
    // GetBuilders (e.g. the profile page underneath) must not be rebuilt while
    // this page is still being built.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Get.find<WalletController>().loadWallet(),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isWeb) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      Get.find<WalletController>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = WebTopNav.isEnabled(context);
    _isWeb = isWeb;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.scaffoldBackground,
      appBar: isWeb
          ? WebTopNav(
              selectedIndex: null,
              onDestinationSelected: (index) =>
                  DashboardTabs.open(context, index),
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            )
          : AppBar(
              title: Text(
                'my_wallet'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeExtraLarge,
                  color: ColorResource.textWhite,
                ),
              ),
              backgroundColor: ColorResource.primaryDark,
              foregroundColor: ColorResource.textWhite,
              elevation: 0,
            ),
      endDrawer: isWeb ? const WebProfileDrawer() : null,
      body: AuthGate(
        child: GetBuilder<WalletController>(
          builder: (wallet) => GetBuilder<ProfileController>(
            builder: (_) => RefreshIndicator(
              onRefresh: wallet.loadWallet,
              color: ColorResource.primaryDark,
              child: LayoutBuilder(
                builder: (context, viewport) => SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: ConstrainedBox(
                    // Web: at least a viewport tall so the footer sits at the
                    // bottom of a short page.
                    constraints: BoxConstraints(
                      minHeight: isWeb ? viewport.maxHeight : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: isWeb
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            isWeb ? 0 : Constants.paddingSizeDefault,
                            Constants.paddingSizeDefault,
                            isWeb ? 0 : Constants.paddingSizeDefault,
                            Constants.paddingSizeExtraLarge,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWeb
                                    ? WebTopNav.maxContentWidth
                                    : double.infinity,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWeb
                                      ? WebTopNav.bandInsetFor(
                                          MediaQuery.of(context).size.width,
                                        )
                                      : 0,
                                ),
                                child: isWeb
                                    ? _buildWebContent(wallet)
                                    : _buildMobileContent(wallet),
                              ),
                            ),
                          ),
                        ),
                        if (isWeb) const WebFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebContent(WalletController wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'my_wallet'.tr,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeOverLarge,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeLarge),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 42,
              child: WalletBalanceCard(balance: wallet.balance),
            ),
            const SizedBox(width: 32),
            Expanded(flex: 58, child: _buildHistory(wallet)),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileContent(WalletController wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WalletBalanceCard(balance: wallet.balance),
        const SizedBox(height: Constants.spaceSection),
        _buildHistory(wallet),
      ],
    );
  }

  Widget _buildHistory(WalletController wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'wallet_transactions'.tr,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeExtraSmall),
        Text(
          'wallet_transactions_subtitle'.tr,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeDefault),
        ..._buildHistoryBody(wallet),
      ],
    );
  }

  List<Widget> _buildHistoryBody(WalletController wallet) {
    if (wallet.isLoading && wallet.transactions.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(Constants.paddingSizeExtraLarge),
          child: Center(
            child: CircularProgressIndicator(color: ColorResource.primaryDark),
          ),
        ),
      ];
    }
    if (wallet.errorKey != null && wallet.transactions.isEmpty) {
      return [
        _buildMessage(
          icon: Icons.cloud_off_rounded,
          title: wallet.errorKey!.tr,
          action: TextButton(
            onPressed: wallet.loadWallet,
            style: TextButton.styleFrom(
              foregroundColor: ColorResource.primaryDark,
            ),
            child: Text('retry'.tr, style: poppinsMedium),
          ),
        ),
      ];
    }
    if (wallet.transactions.isEmpty) {
      return [
        _buildMessage(
          icon: Icons.receipt_long_outlined,
          title: 'no_wallet_transactions_yet'.tr,
          message: 'no_wallet_transactions_message'.tr,
        ),
      ];
    }

    return [
      for (final transaction in wallet.transactions)
        Padding(
          padding: const EdgeInsets.only(bottom: Constants.paddingSizeSmall),
          child: WalletTransactionTile(transaction: transaction),
        ),
      if (wallet.hasMore) _buildPagingFooter(wallet),
    ];
  }

  /// Mobile shows a spinner while the next page loads; web offers a
  /// "View more" button (same pill as order history).
  Widget _buildPagingFooter(WalletController wallet) {
    final Widget child;
    if (wallet.isLoadingMore) {
      child = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: ColorResource.primaryDark,
        ),
      );
    } else if (_isWeb) {
      child = OutlinedButton.icon(
        onPressed: wallet.loadMore,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        label: Text('view_more'.tr, style: poppinsMedium),
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorResource.primaryDark,
          side: const BorderSide(color: ColorResource.primaryDark, width: 1.4),
          padding: const EdgeInsets.symmetric(
            horizontal: Constants.paddingSizeExtraLarge,
            vertical: Constants.paddingSizeSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
          ),
        ),
      );
    } else {
      child = const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Constants.paddingSizeDefault),
      child: Center(child: child),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    String? message,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Constants.paddingSizeExtraLarge),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        border: Border.all(color: context.textLight.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: context.textLight, size: 40),
          const SizedBox(height: Constants.paddingSizeSmall),
          Text(
            title,
            textAlign: TextAlign.center,
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textPrimary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: Constants.paddingSizeExtraSmall),
            Text(
              message,
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          ?action,
        ],
      ),
    );
  }
}
