import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Mar 5, 2026" — shared by the hero card and the details sections.
String formatCouponDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

/// The single state a coupon is in, most blocking first — the hero shows one
/// clear status instead of a row of overlapping badges.
enum _CouponState { inactive, expired, limitReached, notYetValid, active }

/// Ticket-style header for the coupon details: status, the offer as the
/// headline, its key conditions, a perforated tear line and the code with a
/// copy action. Muted when the coupon can't be used.
class CouponHeroCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onCopy;

  /// Radius of the half-circle notches cut into each side at the tear line.
  static const double _notchRadius = 11;

  const CouponHeroCard({super.key, required this.coupon, required this.onCopy});

  _CouponState get _state {
    final now = DateTime.now();
    if (!coupon.isActive) return _CouponState.inactive;
    if (now.isAfter(coupon.validUntil)) return _CouponState.expired;
    if (coupon.usageLimit != null && coupon.usedCount >= coupon.usageLimit!) {
      return _CouponState.limitReached;
    }
    if (now.isBefore(coupon.validFrom)) return _CouponState.notYetValid;
    return _CouponState.active;
  }

  /// Offer headline: "20%" or the fixed amount in the store's currency.
  String get _discountText => coupon.discountType == 'percentage'
      ? '${coupon.discountValue.toStringAsFixed(0)}%'
      : CurrencyHelper.formatAmount(coupon.discountValue);

  /// "Min. order ৳500 • Up to ৳100" — only the conditions that apply.
  String get _conditionsText {
    final parts = <String>[
      coupon.minOrderAmount != null
          ? '${'min_order_short'.tr} ${CurrencyHelper.formatAmount(coupon.minOrderAmount!)}'
          : 'no_minimum_required'.tr,
      if (coupon.maxDiscount != null)
        '${'up_to'.tr} ${CurrencyHelper.formatAmount(coupon.maxDiscount!)}',
    ];
    return parts.join('  •  ');
  }

  String get _validityText {
    final now = DateTime.now();
    switch (_state) {
      case _CouponState.notYetValid:
        return '${'starts_on'.tr} ${formatCouponDate(coupon.validFrom)}';
      case _CouponState.expired:
        return '${'expired_on'.tr} ${formatCouponDate(coupon.validUntil)}';
      default:
        final days = coupon.validUntil.difference(now).inDays;
        final until = '${'valid_until'.tr} ${formatCouponDate(coupon.validUntil)}';
        if (_state != _CouponState.active) return until;
        return days <= 0
            ? '$until  •  ${'expires_today'.tr}'
            : '$until  •  $days ${'days_left'.tr}';
    }
  }

  ({String label, IconData icon}) get _statusVisual {
    switch (_state) {
      case _CouponState.inactive:
        return (label: 'inactive'.tr, icon: Icons.pause_circle_rounded);
      case _CouponState.expired:
        return (label: 'expired'.tr, icon: Icons.event_busy_rounded);
      case _CouponState.limitReached:
        return (label: 'limit_reached'.tr, icon: Icons.block_rounded);
      case _CouponState.notYetValid:
        return (label: 'not_yet_valid'.tr, icon: Icons.schedule_rounded);
      case _CouponState.active:
        return (label: 'coupon_active'.tr, icon: Icons.check_circle_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUsable = _state == _CouponState.active;
    final primary = Theme.of(context).primaryColor;
    // Brand gradient when usable; a neutral slate that reads in both themes
    // when it isn't, so an expired coupon never looks redeemable.
    final gradient = isUsable
        ? [primary, Color.lerp(primary, Colors.black, 0.25)!]
        : [Colors.blueGrey.shade400, Colors.blueGrey.shade600];

    return Container(
      margin: const EdgeInsets.all(Constants.paddingSizeDefault),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Soft decorative rings in the corner for depth.
              Positioned(top: -40, right: -30, child: _ring(140)),
              Positioned(top: 30, right: 40, child: _ring(60)),
              Padding(
                padding: const EdgeInsets.all(Constants.paddingSizeLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopRow(),
                    const SizedBox(height: Constants.paddingSizeDefault),
                    _buildOffer(),
                    const SizedBox(height: Constants.paddingSizeLarge),
                    _buildTearLine(context),
                    const SizedBox(height: Constants.paddingSizeLarge),
                    _buildCodeRow(primary, isUsable),
                    const SizedBox(height: Constants.paddingSizeSmall + 2),
                    _buildValidity(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ring(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.07),
        ),
      );

  Widget _buildTopRow() {
    final status = _statusVisual;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Constants.paddingSizeSmall,
            vertical: Constants.paddingSizeExtraSmall,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(status.icon, size: 14, color: ColorResource.textWhite),
              const SizedBox(width: Constants.paddingSizeExtraSmall),
              Text(
                status.label,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.textWhite,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(Constants.paddingSizeSmall),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          child: const Icon(
            Icons.local_offer_rounded,
            size: 22,
            color: ColorResource.textWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildOffer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                _discountText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: poppinsBold.copyWith(
                  fontSize: 40,
                  height: 1.1,
                  color: ColorResource.textWhite,
                ),
              ),
            ),
            const SizedBox(width: Constants.paddingSizeExtraSmall + 1),
            Text(
              'off'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeExtraLarge,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        const SizedBox(height: Constants.paddingSizeExtraSmall),
        Text(
          _conditionsText,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeSmall + 1,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  /// Dashed tear line with half-circle notches bitten out of both edges. The
  /// notches are filled with the page background and pushed past the padding
  /// so the card's clip leaves exactly half of each circle visible.
  Widget _buildTearLine(BuildContext context) {
    const edge = Constants.paddingSizeLarge + _notchRadius;
    final notch = Container(
      width: _notchRadius * 2,
      height: _notchRadius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.scaffoldBackground,
      ),
    );

    return SizedBox(
      height: _notchRadius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const dash = 6.0, gap = 5.0;
              final count =
                  (constraints.maxWidth / (dash + gap)).floor().clamp(1, 200);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  count,
                  (_) => Container(
                    width: dash,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              );
            },
          ),
          PositionedDirectional(start: -edge, child: notch),
          PositionedDirectional(end: -edge, child: notch),
        ],
      ),
    );
  }

  Widget _buildCodeRow(Color primary, bool isUsable) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeDefault,
              vertical: Constants.paddingSizeSmall + 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'coupon_code'.tr,
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeExtraSmall + 1,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  coupon.code,
                  maxLines: 1,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeExtraLarge,
                    letterSpacing: 2,
                    color: ColorResource.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: Constants.paddingSizeSmall),
        SizedBox(
          height: Constants.minTapTarget + Constants.paddingSizeDefault,
          child: ElevatedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(
              'copy'.tr,
              style: poppinsBold.copyWith(fontSize: Constants.fontSizeDefault),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: ColorResource.textWhite,
              foregroundColor: isUsable ? primary : Colors.blueGrey.shade600,
              padding: const EdgeInsets.symmetric(
                horizontal: Constants.paddingSizeDefault,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidity() {
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 14,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        const SizedBox(width: Constants.paddingSizeExtraSmall),
        Expanded(
          child: Text(
            _validityText,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}
