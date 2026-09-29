import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// DD : HH : MM : SS translucent boxes ticking down to the sale end. Sits on
/// a [FlashSaleBackdrop]; [large] is the full-page banner size.
class FlashSaleCountdown extends StatelessWidget {
  final Duration remaining;
  final bool large;

  const FlashSaleCountdown({
    super.key,
    required this.remaining,
    this.large = false,
  });

  String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    // The day chip only appears while a day or more remains, then the timer
    // continues as HH : MM : SS.
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    final double fontSize = large
        ? Constants.fontSizeLarge
        : Constants.fontSizeSmall;
    final white = ColorResource.textWhite;

    Widget chip(String text) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 7,
        vertical: large ? 7 : 4,
      ),
      decoration: BoxDecoration(
        color: white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(
          large ? Constants.radiusDefault : Constants.radiusSmall + 2,
        ),
        border: Border.all(color: white.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: poppinsBold.copyWith(
          fontSize: fontSize,
          color: white,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    Widget colon() => Padding(
      padding: EdgeInsets.symmetric(horizontal: large ? 4 : 2),
      child: Text(
        ':',
        style: poppinsBold.copyWith(
          fontSize: fontSize,
          color: white.withValues(alpha: 0.85),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (days > 0) ...[chip('${_two(days)} ${'day_short'.tr}'), colon()],
        chip('${_two(hours)} h'),
        colon(),
        chip('${_two(minutes)} m'),
        colon(),
        chip('${_two(seconds)} s'),
      ],
    );
  }
}
