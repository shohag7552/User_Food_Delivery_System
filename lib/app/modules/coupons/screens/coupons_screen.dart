import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/controllers/coupon_controller.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/modules/coupons/screens/coupon_details_screen.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CouponsScreen extends StatefulWidget {
  final bool isSelectionMode;
  final Function(CouponModel)? onCouponSelected;
  
  const CouponsScreen({
    super.key,
    this.isSelectionMode = false,
    this.onCouponSelected,
  });

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final CouponController _controller = Get.find<CouponController>();

  @override
  void initState() {
    super.initState();
    _controller.getCoupons();
  }

  void _confirmDelete(String id, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Coupon',
          style: poppinsBold.copyWith(
            fontSize: 18,
            color: Theme.of(context).primaryColor,
          ),
        ),
        content: Text(
          'Are you sure you want to delete coupon "$code"?',
          style: poppinsRegular.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: poppinsMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _controller.deleteCoupon(id);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: poppinsMedium.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppbar(
        title: widget.isSelectionMode ? 'Select Coupon' : 'Coupons',
      ),
      body: GetBuilder<CouponController>(
        builder: (controller) {
          if (controller.isLoading && controller.coupons == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.coupons == null || controller.coupons!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_rounded,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Coupons Yet',
                    style: poppinsBold.copyWith(
                      fontSize: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first coupon',
                    style: poppinsRegular.copyWith(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.getCoupons(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.coupons!.length,
              itemBuilder: (context, index) {
                final coupon = controller.coupons![index];
                return _CouponCard(
                  coupon: coupon,
                  isSelectionMode: widget.isSelectionMode,
                  onSelect: widget.onCouponSelected,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final bool isSelectionMode;
  final Function(CouponModel)? onSelect;

  const _CouponCard({
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

  void _handleTap(BuildContext context) {
    // Import the details screen at the top of the file
    Get.to(
      () => CouponDetailsScreen(
        coupon: coupon,
        isSelectionMode: isSelectionMode,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = DateTime.now().isAfter(coupon.validUntil);
    final isNotYetValid = DateTime.now().isBefore(coupon.validFrom);
    final isUsageLimitReached = coupon.usageLimit != null && 
        coupon.usedCount >= coupon.usageLimit!;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          border: Border.all(
            color: !coupon.isActive || isExpired || isNotYetValid || isUsageLimitReached
                ? Colors.red.withValues(alpha: 0.3)
                : Theme.of(context).primaryColor.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header with code and status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: !coupon.isActive || isExpired || isNotYetValid || isUsageLimitReached
                      ? [Colors.grey[400]!, Colors.grey[500]!]
                      : [
                          Theme.of(context).primaryColor,
                          Theme.of(context).colorScheme.secondary,
                        ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_offer_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coupon.code,
                                style: poppinsBold.copyWith(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                coupon.discountDisplay,
                                style: poppinsMedium.copyWith(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.white),
                    onPressed: () => _copyCouponCode(context),
                    tooltip: 'Copy code',
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    coupon.description,
                    style: poppinsRegular.copyWith(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Details Grid
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (coupon.minOrderAmount != null)
                        _DetailChip(
                          icon: Icons.shopping_cart_rounded,
                          label: 'Min: ${CurrencyHelper.formatAmount(coupon.minOrderAmount!)}',
                        ),
                      if (coupon.maxDiscount != null)
                        _DetailChip(
                          icon: Icons.discount_rounded,
                          label: 'Max: ${CurrencyHelper.formatAmount(coupon.maxDiscount!)}',
                        ),
                      if (coupon.usageLimit != null)
                        _DetailChip(
                          icon: Icons.people_rounded,
                          label: '${coupon.usedCount}/${coupon.usageLimit}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Validity Period
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_formatDate(coupon.validFrom)} - ${_formatDate(coupon.validUntil)}',
                          style: poppinsRegular.copyWith(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
                      if (coupon.isActive && !isExpired && !isNotYetValid && !isUsageLimitReached)
                        _StatusBadge(
                          label: 'Active',
                          color: Colors.green,
                          icon: Icons.check_circle_rounded,
                        ),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: poppinsMedium.copyWith(
              fontSize: 12,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
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
