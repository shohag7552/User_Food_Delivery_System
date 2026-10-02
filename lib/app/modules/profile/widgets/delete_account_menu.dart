import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Overflow (⋮) menu in the My Profile header holding "Delete account".
///
/// Tucked behind a menu rather than shown as a bare button: it is destructive
/// and rarely used, so it should be findable but never one stray tap away.
/// The menu item still only opens a confirmation dialog.
class DeleteAccountMenu extends StatelessWidget {
  const DeleteAccountMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ProfileMenuAction>(
      tooltip: 'more_options'.tr,
      icon: Icon(Icons.more_vert_rounded, color: ColorResource.textWhite),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
      ),
      onSelected: (action) {
        if (action == _ProfileMenuAction.deleteAccount) {
          showDeleteAccountDialog(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ProfileMenuAction.deleteAccount,
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline,
                size: 20,
                color: ColorResource.error,
              ),
              const SizedBox(width: Constants.paddingSizeSmall),
              Text(
                'delete_account'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _ProfileMenuAction { deleteAccount }

/// Confirms, then permanently deletes the signed-in account and returns to
/// the dashboard as a guest.
void showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'delete_account'.tr,
        style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
      ),
      content: Text(
        'delete_account_warning'.tr,
        style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            'cancel'.tr,
            style: poppinsMedium.copyWith(color: context.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorResource.error,
          ),
          onPressed: () async {
            Navigator.pop(dialogContext);
            final ok = await Get.find<AuthController>().deleteAccount();
            if (ok && context.mounted) context.goNamed(RouteNames.dashboard);
          },
          child: Text(
            'delete'.tr,
            style: poppinsBold.copyWith(color: ColorResource.textWhite),
          ),
        ),
      ],
    ),
  );
}
