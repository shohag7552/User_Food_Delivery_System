import 'package:appwrite_user_app/app/common/widgets/hover_arrow_carousel.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/controllers/flash_sale_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/flash_sale/widgets/flash_sale_item_card.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Ecommerce home "⚡ Flash Sale" strip: gradient header with a live
/// countdown + see-all, and a horizontal carousel of flash item cards.
/// Renders nothing when no sale is live.
class FlashSaleSection extends StatelessWidget {
  final bool isWide;

  const FlashSaleSection({super.key, required this.isWide});

  /// Matches the ecommerce home's content cap (+32 keeps the inner 16px list
  /// padding aligned with the other hPad-gutter sections).
  static const double _maxSectionWidth = 1232;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FlashSaleController>(
      builder: (controller) {
        if (!controller.hasActiveSale) return const SizedBox.shrink();

        final sale = controller.activeSale!;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxSectionWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Gradient header: title, countdown, see-all. Adapts to the
                // available width — one row when everything fits; on compact
                // (phone) widths the countdown moves to its own line so the
                // title and chips never break or overflow.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: ColorResource.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(Constants.radiusLarge),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Titles + countdown (incl. a possible day chip) +
                        // see-all need roughly this much to share one row.
                        final bool compact = constraints.maxWidth < 480;

                        final Widget titles = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'flash_sale'.tr,
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeLarge,
                                color: ColorResource.textWhite,
                              ),
                            ),
                            if (sale.title.isNotEmpty)
                              Text(
                                sale.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: poppinsRegular.copyWith(
                                  fontSize: Constants.fontSizeSmall,
                                  color: ColorResource.textWhite
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                          ],
                        );

                        final Widget countdown =
                            _CountdownChips(remaining: controller.remaining);

                        final Widget seeAll = InkWell(
                          onTap: () =>
                              context.pushNamed(RouteNames.flashSale),
                          borderRadius:
                              BorderRadius.circular(Constants.radiusLarge),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'see_all'.tr,
                                  style: poppinsBold.copyWith(
                                    fontSize: Constants.fontSizeSmall,
                                    color: ColorResource.textWhite,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: ColorResource.textWhite,
                                ),
                              ],
                            ),
                          ),
                        );

                        if (!compact) {
                          return Row(
                            children: [
                              const Text('⚡', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 6),
                              Expanded(child: titles),
                              const SizedBox(width: 10),
                              countdown,
                              const SizedBox(width: 6),
                              seeAll,
                            ],
                          );
                        }

                        // Compact: titles + see-all share the first line; the
                        // countdown gets its own line. The FittedBox shrinks
                        // the chips as a last resort on ultra-narrow screens
                        // instead of overflowing.
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('⚡',
                                    style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 6),
                                Expanded(child: titles),
                                const SizedBox(width: 6),
                                seeAll,
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: countdown,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cards strip — hover arrows on wide/web layouts.
                HoverArrowCarousel(
                  height: isWide ? 356 : 296,
                  builder: (context, carouselController) =>
                      ListView.separated(
                    controller: carouselController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    itemCount: controller.items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final card = SizedBox(
                        width: isWide ? 230 : 175,
                        child: FlashSaleItemCard(
                          item: controller.items[index],
                        ),
                      );
                      return isWide ? HoverLift(child: card) : card;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// HH : MM : SS boxes ticking down to the sale end.
class _CountdownChips extends StatelessWidget {
  final Duration remaining;

  const _CountdownChips({required this.remaining});

  String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    // DD : HH : MM : SS — the day chip only appears while a day or more
    // remains, then the timer continues as HH : MM : SS.
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: ColorResource.textWhite,
            ),
          ),
        );

    Widget colon() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            ':',
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: ColorResource.textWhite,
            ),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (days > 0) ...[
          chip('${_two(days)} ${'day_short'.tr}'),
          colon(),
        ],
        chip('${_two(hours)} h'),
        colon(),
        chip('${_two(minutes)} m'),
        colon(),
        chip('${_two(seconds)} s'),
      ],
    );
  }
}
