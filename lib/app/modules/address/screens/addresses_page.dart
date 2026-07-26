import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/web_footer.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/address_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

enum _AddressCardAction { setDefault, edit, delete }

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Caps the list width on desktop web so cards stay readable instead of
  /// stretching edge to edge.
  static const double _maxContentWidth = 1080;

  /// At or above this inner width the web layout shows two card columns.
  static const double _twoColumnWidth = 760;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Desktop web keeps the shared top-nav + account drawer; mobile/tablet use
    // the page's own app bar with a back button.
    final showWebNav = WebTopNav.isEnabled(context);

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
          : CustomAppbar(title: 'saved_addresses'.tr),
      endDrawer: showWebNav ? const WebProfileDrawer() : null,
      body: AuthGate(
        child: GetBuilder<AddressController>(
          builder: (controller) {
            if (controller.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: ColorResource.primaryDark,
                ),
              );
            }

            if (showWebNav) return _buildWebBody(context, controller);

            // Mobile / tablet: plain full-width list (or the empty state).
            if (!controller.hasAddresses) return _buildEmptyState();
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.addresses.length,
              itemBuilder: (context, index) {
                final address = controller.addresses[index];
                return _buildAddressCard(context, address, controller);
              },
            );
          },
        ),
      ),
      // The web header carries its own "Add address" button, so the FAB is
      // mobile-only.
      floatingActionButton: showWebNav
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                context.pushNamed(RouteNames.addEditAddress);
              },
              backgroundColor: ColorResource.primaryDark,
              label: Text(
                'add_address'.tr,
                style: poppinsBold.copyWith(color: ColorResource.textWhite),
              ),
              icon: Icon(Icons.add, color: ColorResource.textWhite),
            ),
    );
  }

  /// Desktop web: a full-width scroll surface (drag anywhere, including the side
  /// gutters, to scroll). The content is centred + width-capped; the footer is
  /// full-width and pinned to the BOTTOM of the viewport (spaceBetween pushes it
  /// down when content is short, and it flows after the content when tall).
  Widget _buildWebBody(BuildContext context, AddressController controller) {
    return LayoutBuilder(
      builder: (context, viewport) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            // Force the column to be at least a full viewport tall so the footer
            // can be anchored to the bottom even when the content is short.
            constraints: BoxConstraints(minHeight: viewport.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Content (centred, width-capped) ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Constants.paddingSizeExtraLarge,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _maxContentWidth),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Constants.paddingSizeLarge,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: title + add button.
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'saved_addresses'.tr,
                                    style: poppinsBold.copyWith(
                                      fontSize: Constants.fontSizeOverLarge,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => context
                                      .pushNamed(RouteNames.addEditAddress),
                                  icon: Icon(Icons.add,
                                      color: ColorResource.textWhite),
                                  label: Text(
                                    'add_address'.tr,
                                    style: poppinsBold.copyWith(
                                      color: ColorResource.textWhite,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorResource.primaryDark,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.paddingSizeLarge,
                                      vertical: Constants.paddingSizeDefault,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          Constants.radiusLarge),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Constants.paddingSizeLarge),

                            // Content: responsive card grid, or empty state.
                            if (!controller.hasAddresses)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 40),
                                child: _buildEmptyState(),
                              )
                            else
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final width = constraints.maxWidth;
                                  final columns =
                                      width >= _twoColumnWidth ? 2 : 1;
                                  const spacing = 16.0;
                                  final itemWidth =
                                      (width - (columns - 1) * spacing) /
                                          columns;

                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: 0,
                                    children: [
                                      for (final address
                                          in controller.addresses)
                                        SizedBox(
                                          width: itemWidth,
                                          child: _buildAddressCard(
                                            context,
                                            address,
                                            controller,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Full-width footer, anchored to the bottom ───────────────
                const WebFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 100,
            color: ColorResource.textLight,
          ),
          const SizedBox(height: 20),
          Text(
            'no_addresses_saved'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'add_an_address_to_get_started'.tr,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    AddressModel address,
    AddressController controller,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final addressTextColor =
        theme.textTheme.bodyMedium?.color ?? context.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: isDark ? 18 : 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: address.isDefault
              ? ColorResource.primaryDark.withValues(alpha: 0.28)
              : theme.dividerColor.withValues(alpha: 0.2),
          width: .5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 10, 18),
        decoration: BoxDecoration(
          color: address.isDefault
              ? ColorResource.primaryDark.withValues(
                  alpha: isDark ? 0.12 : 0.04,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColorResource.primaryDark.withValues(
                  alpha: address.isDefault ? 0.14 : 0.08,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                address.isDefault
                    ? Icons.location_on_rounded
                    : Icons.location_on_outlined,
                size: 20,
                color: ColorResource.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.name,
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color:
                                theme.textTheme.titleMedium?.color ??
                                context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 10),
                        _buildDefaultBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    address.fullAddress,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      height: 1.5,
                      color: addressTextColor.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<_AddressCardAction>(
              tooltip: MaterialLocalizations.of(context).showMenuTooltip,
              onSelected: (action) => _onAddressActionSelected(
                context,
                action,
                address,
                controller,
              ),
              itemBuilder: (context) {
                final items = <PopupMenuEntry<_AddressCardAction>>[];

                if (!address.isDefault) {
                  items.add(
                    PopupMenuItem<_AddressCardAction>(
                      value: _AddressCardAction.setDefault,
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18),
                          const SizedBox(width: 10),
                          Text('set_as_default_address'.tr),
                        ],
                      ),
                    ),
                  );
                }

                items.addAll([
                  PopupMenuItem<_AddressCardAction>(
                    value: _AddressCardAction.edit,
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text('edit'.tr),
                      ],
                    ),
                  ),
                  PopupMenuItem<_AddressCardAction>(
                    value: _AddressCardAction.delete,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: ColorResource.error,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'delete'.tr,
                          style: poppinsMedium.copyWith(
                            color: ColorResource.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]);

                return items;
              },
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.32 : 0.72,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: theme.iconTheme.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ColorResource.primaryDark.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'default_address'.tr,
        style: poppinsMedium.copyWith(
          fontSize: 11,
          color: ColorResource.primaryDark,
        ),
      ),
    );
  }

  void _onAddressActionSelected(
    BuildContext context,
    _AddressCardAction action,
    AddressModel address,
    AddressController controller,
  ) {
    switch (action) {
      case _AddressCardAction.setDefault:
        controller.setDefaultAddress(address.id);
        break;
      case _AddressCardAction.edit:
        context.pushNamed(RouteNames.addEditAddress, extra: address);
        break;
      case _AddressCardAction.delete:
        _showDeleteConfirmation(context, address, controller);
        break;
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AddressModel address,
    AddressController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'delete_address'.tr,
          style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
        ),
        content: Text(
          'are_you_sure_delete_address'.tr,
          style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr,
              style: poppinsMedium.copyWith(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteAddress(address.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.error,
            ),
            child: Text(
              'delete'.tr,
              style: poppinsBold.copyWith(color: ColorResource.textWhite),
            ),
          ),
        ],
      ),
    );
  }
}
