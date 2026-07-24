import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';

/// A compact, tappable quick-action tile (call / email / directions / website)
/// shown in the row at the top of the Help & Support screen.
class HelpQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const HelpQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Constants.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Constants.paddingSizeSmall,
          vertical: Constants.paddingSizeDefault,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(Constants.paddingSizeSmall),
              decoration: BoxDecoration(
                color: ColorResource.primaryDark
                    .withValues(alpha: isDark ? 0.18 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: ColorResource.primaryDark, size: 22),
            ),
            const SizedBox(height: Constants.paddingSizeSmall),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeExtraSmall,
                color: isDark ? Colors.white : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
