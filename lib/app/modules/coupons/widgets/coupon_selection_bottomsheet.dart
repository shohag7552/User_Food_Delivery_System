import 'package:appwrite_user_app/app/controllers/coupon_controller.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/modules/coupons/screens/coupon_details_screen.dart';
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
                padding: const EdgeInsets.all(20),
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
                          color: ColorResource.textLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: ColorResource.primaryGradient,
                            borderRadius:
                                BorderRadius.circular(Constants.radiusDefault),
                          ),
                          child: Icon(
                            Icons.local_offer_rounded,
                            color: ColorResource.textWhite,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Select Coupon',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeExtraLarge,
                              color: ColorResource.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: ColorResource.textSecondary,
                          ),
                          onPressed: () => Navigator.pop(context),
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
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
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
                              'No Coupons Available',
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeLarge,
                                color: ColorResource.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for deals!',
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
    final now = DateTime.now();
    final isExpired = now.isAfter(coupon.validUntil);
    final isNotYetValid = now.isBefore(coupon.validFrom);
    final isUsageLimitReached =
        coupon.usageLimit != null && coupon.usedCount >= coupon.usageLimit!;
    final isValid =
        coupon.isActive && !isExpired && !isNotYetValid && !isUsageLimitReached;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: ColorResource.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: ColorResource.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: !isValid
                ? ColorResource.error.withOpacity(0.3)
                : ColorResource.primaryDark.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: !isValid
                    ? LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[500]!],
                      )
                    : ColorResource.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Constants.radiusDefault),
                  topRight: Radius.circular(Constants.radiusDefault),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer_rounded,
                    color: ColorResource.textWhite,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon.code,
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: ColorResource.textWhite,
                          ),
                        ),
                        Text(
                          coupon.discountDisplay,
                          style: poppinsMedium.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: ColorResource.textWhite.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      color: ColorResource.textWhite,
                      size: 18,
                    ),
                    onPressed: onCopy,
                    tooltip: 'Copy code',
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.description,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: ColorResource.textLight,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Valid till ${_formatDate(coupon.validUntil)}',
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeExtraSmall,
                            color: ColorResource.textLight,
                          ),
                        ),
                      ),
                      if (isValid)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Valid',
                                style: poppinsBold.copyWith(
                                  fontSize: 10,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ColorResource.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ColorResource.error.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            isExpired
                                ? 'Expired'
                                : isNotYetValid
                                    ? 'Not Yet Valid'
                                    : 'Inactive',
                            style: poppinsBold.copyWith(
                              fontSize: 10,
                              color: ColorResource.error,
                            ),
                          ),
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
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
