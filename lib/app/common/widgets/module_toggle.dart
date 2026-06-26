import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/helper/module_switch_helper.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Food / Shop segmented switch. Renders nothing unless the store runs both
/// modules. Use [onGradient] when placed over the brand-colored header.
class ModuleToggle extends StatelessWidget {
  final bool onGradient;

  const ModuleToggle({super.key, this.onGradient = false});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ModuleController>(
      builder: (module) {
        if (!module.bothEnabled) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: onGradient
                ? Colors.white.withValues(alpha: 0.18)
                : ColorResource.scaffoldBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _segment(
                module,
                ModuleController.food,
                Icons.restaurant_menu,
                'food'.tr,
              ),
              _segment(
                module,
                ModuleController.ecommerce,
                Icons.shopping_bag_outlined,
                'shop'.tr,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _segment(
    ModuleController module,
    String value,
    IconData icon,
    String label,
  ) {
    final selected = module.activeModule == value;
    final inactiveColor =
        onGradient ? Colors.white.withValues(alpha: 0.9) : ColorResource.textSecondary;

    return GestureDetector(
      onTap: selected ? null : () => ModuleSwitchHelper.switchTo(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? ColorResource.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? ColorResource.textWhite : inactiveColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: selected ? ColorResource.textWhite : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
