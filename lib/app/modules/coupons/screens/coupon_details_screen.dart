import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Whether a coupon can currently be applied.
bool _isCouponValid(CouponModel coupon) {
  final now = DateTime.now();
  final isExpired = now.isAfter(coupon.validUntil);
  final isNotYetValid = now.isBefore(coupon.validFrom);
  final isUsageLimitReached =
      coupon.usageLimit != null && coupon.usedCount >= coupon.usageLimit!;
  return coupon.isActive &&
      !isExpired &&
      !isNotYetValid &&
      !isUsageLimitReached;
}

/// Web entry point — shows the coupon details in a centred, width-capped dialog
/// (instead of pushing a full page). Selection mode shows an "apply" footer.
Future<void> showCouponDetailsDialog(
  BuildContext context, {
  required CouponModel coupon,
  bool isSelectionMode = false,
  Function(CouponModel)? onSelect,
}) {
  final isValid = _isCouponValid(coupon);

  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) {
      final maxHeight = MediaQuery.of(dialogContext).size.height * 0.86;
      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        backgroundColor: Colors.grey[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'coupon_details'.tr,
                        style: poppinsBold.copyWith(
                          fontSize: 18,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: MaterialLocalizations.of(dialogContext)
                          .closeButtonLabel,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable details content
              Flexible(
                child: SingleChildScrollView(
                  child: CouponDetailsContent(coupon: coupon),
                ),
              ),

              // Apply footer (selection mode only)
              if (isSelectionMode && isValid)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      onSelect?.call(coupon);
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(dialogContext).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'apply_this_coupon'.tr,
                      style: poppinsBold.copyWith(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Full-page coupon details (mobile / direct route).
class CouponDetailsScreen extends StatelessWidget {
  final CouponModel coupon;
  final bool isSelectionMode;
  final Function(CouponModel)? onSelect;

  const CouponDetailsScreen({
    super.key,
    required this.coupon,
    this.isSelectionMode = false,
    this.onSelect,
  });

  void _selectCoupon(BuildContext context) {
    if (onSelect != null) {
      onSelect!(coupon);
      context.pop(coupon);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _isCouponValid(coupon);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppbar(title: 'coupon_details'.tr),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CouponDetailsContent(coupon: coupon),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: isSelectionMode && isValid
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () => _selectCoupon(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'apply_this_coupon'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// The coupon details body (hero + status badges + info sections). Shared by the
/// full-page screen and the web dialog so the layout is defined once.
class CouponDetailsContent extends StatelessWidget {
  final CouponModel coupon;

  const CouponDetailsContent({super.key, required this.coupon});

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = now.isAfter(coupon.validUntil);
    final isNotYetValid = now.isBefore(coupon.validFrom);
    final isUsageLimitReached =
        coupon.usageLimit != null && coupon.usedCount >= coupon.usageLimit!;
    final isValid =
        coupon.isActive && !isExpired && !isNotYetValid && !isUsageLimitReached;

    return Column(
      children: [
        // Hero Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: !isValid
                  ? [Colors.grey[400]!, Colors.grey[500]!]
                  : [
                      Theme.of(context).primaryColor,
                      Theme.of(context).colorScheme.secondary,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                coupon.code,
                style: poppinsBold.copyWith(
                  fontSize: 32,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                coupon.discountDisplay,
                style: poppinsBold.copyWith(
                  fontSize: 28,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _copyCouponCode(context),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(
                  'copy_code'.tr,
                  style: poppinsMedium.copyWith(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Status Badges
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (!coupon.isActive)
                _StatusBadge(
                  label: 'inactive'.tr,
                  color: Colors.grey,
                  icon: Icons.pause_circle_rounded,
                ),
              if (isExpired)
                _StatusBadge(
                  label: 'expired'.tr,
                  color: Colors.red,
                  icon: Icons.error_rounded,
                ),
              if (isNotYetValid)
                _StatusBadge(
                  label: 'not_yet_valid'.tr,
                  color: Colors.orange,
                  icon: Icons.schedule_rounded,
                ),
              if (isUsageLimitReached)
                _StatusBadge(
                  label: 'limit_reached'.tr,
                  color: Colors.red,
                  icon: Icons.block_rounded,
                ),
              if (isValid)
                _StatusBadge(
                  label: 'active_status'.tr,
                  color: Colors.green,
                  icon: Icons.check_circle_rounded,
                ),
            ],
          ),
        ),

        // Description
        _buildSection(
          context,
          title: 'description'.tr,
          icon: Icons.description_rounded,
          child: Text(
            coupon.description,
            style: poppinsRegular.copyWith(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),

        // Discount Information
        _buildSection(
          context,
          title: 'discount_information'.tr,
          icon: Icons.discount_rounded,
          child: Column(
            children: [
              _buildInfoRow(
                context,
                'discount_type'.tr,
                coupon.discountType == 'percentage'
                    ? 'percentage'.tr
                    : 'fixed_amount'.tr,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'discount_value'.tr,
                coupon.discountDisplay,
              ),
              if (coupon.maxDiscount != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  'max_discount_cap'.tr,
                  CurrencyHelper.formatAmount(coupon.maxDiscount!),
                ),
              ],
            ],
          ),
        ),

        // Conditions
        _buildSection(
          context,
          title: 'conditions'.tr,
          icon: Icons.rule_rounded,
          child: Column(
            children: [
              if (coupon.minOrderAmount != null)
                _buildInfoRow(
                  context,
                  'min_order_amount'.tr,
                  CurrencyHelper.formatAmount(coupon.minOrderAmount!),
                )
              else
                _buildInfoRow(
                  context,
                  'min_order_amount'.tr,
                  'no_minimum_required'.tr,
                ),
            ],
          ),
        ),

        // Usage Statistics
        if (coupon.usageLimit != null)
          _buildSection(
            context,
            title: 'usage_statistics'.tr,
            icon: Icons.people_rounded,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'times_used'.tr,
                      style: poppinsRegular.copyWith(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${coupon.usedCount} / ${coupon.usageLimit}',
                      style: poppinsBold.copyWith(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: coupon.usedCount / coupon.usageLimit!,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      coupon.usedCount >= coupon.usageLimit!
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          _buildSection(
            context,
            title: 'usage_statistics'.tr,
            icon: Icons.people_rounded,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'times_used'.tr,
                      style: poppinsRegular.copyWith(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${coupon.usedCount}',
                      style: poppinsBold.copyWith(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'no_usage_limit'.tr,
                  style: poppinsRegular.copyWith(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

        // Validity Period
        _buildSection(
          context,
          title: 'validity_period'.tr,
          icon: Icons.calendar_today_rounded,
          child: Column(
            children: [
              _buildInfoRow(
                context,
                'valid_from'.tr,
                _formatDate(coupon.validFrom),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'valid_until'.tr,
                _formatDate(coupon.validUntil),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'days_remaining'.tr,
                    style: poppinsRegular.copyWith(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    isExpired
                        ? 'expired'.tr
                        : isNotYetValid
                            ? 'not_yet_active'.tr
                            : '${coupon.validUntil.difference(now).inDays} ${'days'.tr}',
                    style: poppinsBold.copyWith(
                      fontSize: 14,
                      color: isExpired
                          ? Colors.red
                          : isNotYetValid
                              ? Colors.orange
                              : Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: poppinsBold.copyWith(
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: poppinsRegular.copyWith(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: poppinsBold.copyWith(
            fontSize: 14,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: poppinsMedium.copyWith(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
