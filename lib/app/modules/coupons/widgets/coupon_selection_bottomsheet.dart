import 'package:appwrite_user_app/app/controllers/coupon_controller.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CouponSelectionBottomSheet extends StatefulWidget {
  const CouponSelectionBottomSheet({super.key});

  @override
  State<CouponSelectionBottomSheet> createState() =>
      _CouponSelectionBottomSheetState();

  static Future<CouponModel?> show(BuildContext context) async {
    return await showModalBottomSheet<CouponModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CouponSelectionBottomSheet(),
    );
  }
}

class _CouponSelectionBottomSheetState
    extends State<CouponSelectionBottomSheet> {
  final CouponController _controller = Get.find<CouponController>();

  @override
  void initState() {
    super.initState();
    _controller.getCoupons();
  }

  void _copyCouponCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'coupon_code_copied'.tr,
          style: poppinsMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _selectCoupon(CouponModel coupon) {
    // Navigate to details first
    Get.back(result: coupon);
    // Get.to(
    //   () => CouponDetailsScreen(
    //     coupon: coupon,
    //     isSelectionMode: true,
    //     onSelect: (selectedCoupon) {
    //       Navigator.pop(context, selectedCoupon);
    //     },
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: ColorResource.cardBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Constants.radiusExtraLarge),
              topRight: Radius.circular(Constants.radiusExtraLarge),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
                decoration: BoxDecoration(
                  color: ColorResource.cardBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Constants.radiusExtraLarge),
                    topRight: Radius.circular(Constants.radiusExtraLarge),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorResource.shadowLight,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ColorResource.textLight.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: ColorResource.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              Constants.radiusDefault,
                            ),
                          ),
                          child: Icon(
                            Icons.local_offer_rounded,
                            color: ColorResource.textWhite,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'select_coupon'.tr,
                                style: poppinsBold.copyWith(
                                  fontSize: Constants.fontSizeExtraLarge,
                                  color: ColorResource.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'choose_a_coupon_to_save'.tr,
                                style: poppinsRegular.copyWith(
                                  fontSize: Constants.fontSizeSmall,
                                  color: ColorResource.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: ColorResource.scaffoldBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: ColorResource.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Coupon List
              Expanded(
                child: GetBuilder<CouponController>(
                  builder: (controller) {
                    if (controller.isLoading && controller.coupons == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.coupons == null ||
                        controller.coupons!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_rounded,
                              size: 80,
                              color: ColorResource.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'no_coupons_available'.tr,
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeLarge,
                                color: ColorResource.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'check_back_later_deals'.tr,
                              style: poppinsRegular.copyWith(
                                fontSize: Constants.fontSizeDefault,
                                color: ColorResource.textLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => controller.getCoupons(),
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.coupons!.length,
                        itemBuilder: (context, index) {
                          final coupon = controller.coupons![index];
                          return _CouponCard(
                            coupon: coupon,
                            onTap: () => _selectCoupon(coupon),
                            onCopy: () => _copyCouponCode(context, coupon.code),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _CouponCard({
    required this.coupon,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isExpired = now.isAfter(coupon.validUntil);
    final isNotYetValid = now.isBefore(coupon.validFrom);
    final isUsageLimitReached =
        coupon.usageLimit != null && coupon.usedCount >= coupon.usageLimit!;
    final isValid =
        coupon.isActive && !isExpired && !isNotYetValid && !isUsageLimitReached;
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isValid
        ? ColorResource.primaryDark
        : theme.disabledColor;
    final titleColor = isValid
        ? theme.textTheme.titleMedium?.color ?? ColorResource.textPrimary
        : (theme.textTheme.titleMedium?.color ?? ColorResource.textPrimary)
              .withValues(alpha: 0.72);
    final bodyColor = isValid
        ? theme.textTheme.bodyMedium?.color ?? ColorResource.textSecondary
        : (theme.textTheme.bodyMedium?.color ?? ColorResource.textSecondary)
              .withValues(alpha: 0.68);
    final statusBackground = isValid
        ? accentColor.withValues(alpha: 0.10)
        : ColorResource.error.withValues(alpha: 0.10);
    final statusBorder = isValid
        ? accentColor.withValues(alpha: 0.16)
        : ColorResource.error.withValues(alpha: 0.18);
    final statusColor = isValid ? accentColor : ColorResource.error;

    return GestureDetector(
      onTap: isValid ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isValid
                  ? theme.shadowColor.withValues(alpha: isDark ? 0.22 : 0.06)
                  : theme.shadowColor.withValues(alpha: isDark ? 0.18 : 0.04),
              blurRadius: isDark ? 18 : 14,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isValid
                ? ColorResource.primaryDark.withValues(alpha: 0.18)
                : theme.dividerColor.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: isValid
                ? ColorResource.primaryDark.withValues(
                    alpha: isDark ? 0.08 : 0.03,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border(
              left: BorderSide(
                color: accentColor.withValues(alpha: 0.9),
                width: 4,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.12),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        coupon.code,
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      coupon.description,
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: coupon.discountDisplay,
                            style: poppinsBold.copyWith(
                              fontSize: 22,
                              color: accentColor,
                            ),
                          ),
                          TextSpan(
                            text: ' OFF',
                            style: poppinsMedium.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: bodyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: bodyColor.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${'valid_till'.tr} ${_formatDate(coupon.validUntil)}',
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeExtraSmall,
                              color: bodyColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: statusBorder),
                          ),
                          child: Text(
                            isValid
                                ? 'valid'.tr
                                : isExpired
                                ? 'expired'.tr
                                : isNotYetValid
                                ? 'not_yet_valid'.tr
                                : 'inactive'.tr,
                            style: poppinsBold.copyWith(
                              fontSize: 10,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Apply (disabled for invalid coupons)
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: isValid ? onTap : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: accentColor,
                        disabledBackgroundColor:
                            theme.disabledColor.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'apply'.tr,
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeExtraSmall,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: OutlinedButton.icon(
                      onPressed: onCopy,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: BorderSide(
                          color: accentColor.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: Text(
                        'copy'.tr,
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeExtraSmall,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
