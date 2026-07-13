import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/flash_sale_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/modules/flash_sale/widgets/flash_sale_item_card.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full flash-sale page ("see all"): banner with live countdown + a
/// responsive grid of all sale items. Deep-linkable — fetches the sale itself
/// when opened cold.
class FlashSaleScreen extends StatefulWidget {
  const FlashSaleScreen({super.key});

  @override
  State<FlashSaleScreen> createState() => _FlashSaleScreenState();
}

class _FlashSaleScreenState extends State<FlashSaleScreen> {
  static const double _maxContentWidth = 1200;
  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    final controller = Get.find<FlashSaleController>();
    if (!controller.hasActiveSale && !controller.isLoading) {
      controller.getFlashSale();
    }
  }

  @override
  Widget build(BuildContext context) {
    final useWebShell = WebTopNav.isEnabled(context);
    return useWebShell ? _buildWebScaffold() : _buildMobileScaffold();
  }

  Widget _buildMobileScaffold() {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: CustomAppbar(title: 'flash_sale'.tr),
      body: _buildBody(isWide: false),
    );
  }

  Widget _buildWebScaffold() {
    return Scaffold(
      key: _webScaffoldKey,
      backgroundColor: context.scaffoldBackground,
      appBar: WebTopNav(
        selectedIndex: null,
        onDestinationSelected: (index) {
          DashboardTabs.open(context, index);
        },
        onMenuTap: () => _webScaffoldKey.currentState?.openEndDrawer(),
      ),
      endDrawer: const WebProfileDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: _buildBody(isWide: true),
        ),
      ),
    );
  }

  Widget _buildBody({required bool isWide}) {
    return GetBuilder<FlashSaleController>(
      builder: (controller) {
        if (controller.isLoading && !controller.hasActiveSale) {
          return const Center(
            child: CircularProgressIndicator(color: ColorResource.primaryDark),
          );
        }

        if (controller.errorMessage != null && !controller.hasActiveSale) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    color: ColorResource.error, size: 48),
                const SizedBox(height: 12),
                Text(
                  'failed_to_load_flash_sale'.tr,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => controller.getFlashSale(),
                  child: Text(
                    'retry'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (!controller.hasActiveSale) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flash_off_rounded,
                  size: 64,
                  color: context.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'flash_sale_ended'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }

        final sale = controller.activeSale!;

        return RefreshIndicator(
          color: ColorResource.primaryDark,
          onRefresh: () => controller.getFlashSale(reload: true),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Banner: sale title + live countdown.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: ColorResource.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(Constants.radiusLarge),
                      boxShadow: ColorResource.customShadow,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⚡ ${'flash_sale'.tr}',
                                style: poppinsBold.copyWith(
                                  fontSize: Constants.fontSizeExtraLarge,
                                  color: ColorResource.textWhite,
                                ),
                              ),
                              if (sale.title.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  sale.title,
                                  style: poppinsRegular.copyWith(
                                    fontSize: Constants.fontSizeDefault,
                                    color: ColorResource.textWhite
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ends_in'.tr,
                              style: poppinsRegular.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: ColorResource.textWhite
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRemaining(controller.remaining),
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeExtraLarge,
                                color: ColorResource.textWhite,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Items grid — responsive columns, hover lift on web.
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isWide ? 240 : 200,
                    mainAxisExtent: isWide ? 344 : 290,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final card =
                          FlashSaleItemCard(item: controller.items[index]);
                      return isWide ? HoverLift(child: card) : card;
                    },
                    childCount: controller.items.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// DD d HH:MM:SS — the day part only appears while a day or more remains.
  String _formatRemaining(Duration remaining) {
    String two(int v) => v.toString().padLeft(2, '0');
    final days = remaining.inDays;
    final clock =
        '${two(remaining.inHours.remainder(24))}:${two(remaining.inMinutes.remainder(60))}:${two(remaining.inSeconds.remainder(60))}';
    if (days > 0) {
      return '${two(days)}${'day_short'.tr} $clock';
    }
    return clock;
  }
}
