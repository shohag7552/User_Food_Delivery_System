import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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

  void _copyCouponCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: coupon.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Coupon code copied to clipboard',
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

  void _selectCoupon() {
    if (onSelect != null) {
      onSelect!(coupon);
      Get.back(result: coupon);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = now.isAfter(coupon.validUntil);
    final isNotYetValid = now.isBefore(coupon.validFrom);
    final isUsageLimitReached = coupon.usageLimit != null && 
        coupon.usedCount >= coupon.usageLimit!;
    final isValid = coupon.isActive && !isExpired && !isNotYetValid && !isUsageLimitReached;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppbar(title: 'Coupon Details'),
      body: SingleChildScrollView(
        child: Column(
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
                      'Copy Code',
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
                      label: 'Inactive',
                      color: Colors.grey,
                      icon: Icons.pause_circle_rounded,
                    ),
                  if (isExpired)
                    _StatusBadge(
                      label: 'Expired',
                      color: Colors.red,
                      icon: Icons.error_rounded,
                    ),
                  if (isNotYetValid)
                    _StatusBadge(
                      label: 'Not Yet Valid',
                      color: Colors.orange,
                      icon: Icons.schedule_rounded,
                    ),
                  if (isUsageLimitReached)
                    _StatusBadge(
                      label: 'Limit Reached',
                      color: Colors.red,
                      icon: Icons.block_rounded,
                    ),
                  if (isValid)
                    _StatusBadge(
                      label: 'Active',
                      color: Colors.green,
                      icon: Icons.check_circle_rounded,
                    ),
                ],
              ),
            ),

            // Description
            _buildSection(
              context,
              title: 'Description',
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
              title: 'Discount Information',
              icon: Icons.discount_rounded,
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    'Discount Type',
                    coupon.discountType == 'percentage' ? 'Percentage' : 'Fixed Amount',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    'Discount Value',
                    coupon.discountDisplay,
                  ),
                  if (coupon.maxDiscount != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Maximum Discount Cap',
                      CurrencyHelper.formatAmount(coupon.maxDiscount!),
                    ),
                  ],
                ],
              ),
            ),

            // Conditions
            _buildSection(
              context,
              title: 'Conditions',
              icon: Icons.rule_rounded,
              child: Column(
                children: [
                  if (coupon.minOrderAmount != null)
                    _buildInfoRow(
                      context,
                      'Minimum Order Amount',
                      CurrencyHelper.formatAmount(coupon.minOrderAmount!),
                    )
                  else
                    _buildInfoRow(
                      context,
                      'Minimum Order Amount',
                      'No minimum required',
                    ),
                ],
              ),
            ),

            // Usage Statistics
            if (coupon.usageLimit != null)
              _buildSection(
                context,
                title: 'Usage Statistics',
                icon: Icons.people_rounded,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Times Used',
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
                title: 'Usage Statistics',
                icon: Icons.people_rounded,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Times Used',
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
                      'No usage limit',
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
              title: 'Validity Period',
              icon: Icons.calendar_today_rounded,
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    'Valid From',
                    _formatDate(coupon.validFrom),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    'Valid Until',
                    _formatDate(coupon.validUntil),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Days Remaining',
                        style: poppinsRegular.copyWith(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        isExpired
                            ? 'Expired'
                            : isNotYetValid
                                ? 'Not yet active'
                                : '${coupon.validUntil.difference(now).inDays} days',
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
                  onPressed: _selectCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply This Coupon',
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
