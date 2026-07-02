import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/controllers/address_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

enum _AddressCardAction { setDefault, edit, delete }

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppbar(title: 'saved_addresses'.tr),
      body: GetBuilder<AddressController>(
        builder: (controller) {
          if (controller.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: ColorResource.primaryDark,
              ),
            );
          }

          if (!controller.hasAddresses) {
            return _buildEmptyState();
          }

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
      floatingActionButton: FloatingActionButton.extended(
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
        theme.textTheme.bodyMedium?.color ?? ColorResource.textPrimary;

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
                                ColorResource.textPrimary,
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
              style: poppinsMedium.copyWith(color: ColorResource.textSecondary),
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
