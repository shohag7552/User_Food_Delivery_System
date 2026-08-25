import 'dart:math' as math;

import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// How a review form is presented.
///
/// A sheet dragged up from the bottom edge is a phone gesture. On a desktop
/// browser it has no bottom edge to come from — the window is wider than it is
/// tall, and a full-width strip pinned to the floor of a 1600px window reads as
/// a broken page rather than a considered one. There it becomes a centred
/// dialog instead.
enum ReviewSheetMode {
  /// Bottom sheet: rounded top corners, a grabber, bottom safe-area inset.
  sheet,

  /// Centred dialog: rounded on all sides, no grabber, no safe-area inset —
  /// the dialog's own inset padding already keeps it clear of the edges.
  dialog;

  bool get isDialog => this == ReviewSheetMode.dialog;
}

/// Which presentation [context] calls for.
///
/// Deliberately `kIsWeb`-gated rather than width alone: a large Android tablet
/// still has a bottom edge and a thumb near it, so the sheet remains the right
/// gesture there. The 900px threshold matches `WebTopNav.isEnabled`, so the app
/// changes to its desktop shape at one width rather than a different one per
/// screen.
ReviewSheetMode reviewSheetModeFor(BuildContext context) =>
    kIsWeb && MediaQuery.of(context).size.width >= 900
    ? ReviewSheetMode.dialog
    : ReviewSheetMode.sheet;

/// Presents [child] the way [reviewSheetModeFor] says this context wants it.
///
/// Both paths return the same `Future<bool?>`, so callers cannot tell which one
/// ran — the existing `didSubmit == true` checks keep working untouched.
Future<bool?> showReviewSurface({
  required BuildContext context,
  required Widget Function(ReviewSheetMode mode) builder,
}) {
  final mode = reviewSheetModeFor(context);
  final size = MediaQuery.of(context).size;

  if (mode.isDialog) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: Constants.paddingSizeLarge,
          vertical: Constants.paddingSizeExtraLarge,
        ),
        child: ConstrainedBox(
          // Width: a review form is one column of prose and two fields, so it
          // is capped near a comfortable reading measure rather than stretched.
          // Height: the form sizes to its own content and only starts scrolling
          // once it would outgrow the window.
          constraints: BoxConstraints(
            maxWidth: _dialogMaxWidth,
            maxHeight: math.min(size.height * 0.9, _dialogMaxHeight),
          ),
          child: builder(mode),
        ),
      ),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Caps the sheet short of the top edge: even with the keyboard up and the
    // fields filled, what is being reviewed stays on screen.
    constraints: BoxConstraints(maxHeight: size.height * 0.92),
    builder: (_) => builder(mode),
  );
}

const double _dialogMaxWidth = 520;
const double _dialogMaxHeight = 760;

/// Shared chrome for the review sheets, so rating a product and rating a
/// delivery are visibly the same kind of task.
///
/// The grabber and the dismiss control both live in this strip at the very top
/// of the sheet: dismissing is sheet-level furniture, not part of the form, and
/// putting it in the corner keeps the title free to be centred.
class ReviewSheetTopBar extends StatelessWidget {
  const ReviewSheetTopBar({
    super.key,
    required this.onClose,
    this.mode = ReviewSheetMode.sheet,
  });

  final VoidCallback onClose;

  /// Drops the grabber in dialog mode: it advertises a drag-to-dismiss that a
  /// dialog does not support, and pointing at a gesture that does nothing is
  /// worse than showing no affordance at all.
  final ReviewSheetMode mode;

  static const double _height = 46;
  static const double _buttonSize = 34;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Stack(
        children: [
          if (!mode.isDialog)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: Constants.paddingSizeDefault,
                ),
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textLight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(Constants.radiusSmall),
                  ),
                ),
              ),
            ),
          // Directional so the Arabic layout puts it in the leading corner
          // rather than stranding it opposite the reading direction.
          PositionedDirectional(
            top: Constants.paddingSizeSmall - 2,
            end: Constants.paddingSizeSmall - 2,
            child: Material(
              color: context.scaffoldBackground,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onClose,
                child: Tooltip(
                  message: 'close'.tr,
                  child: SizedBox(
                    width: _buttonSize,
                    height: _buttonSize,
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The thing being reviewed, stated once and plainly: a picture of it, its
/// name, and at most one qualifying line.
///
/// It reads as a quoted subject rather than as a form field — a bordered inset
/// panel, not another input — so it is obvious the sheet is *about* this and
/// the form below is the part to fill in.
class ReviewSubjectCard extends StatelessWidget {
  const ReviewSubjectCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.badge,
  });

  /// Product thumbnail or driver avatar — already clipped by the caller, since
  /// only it knows whether the shape should be a rounded square or a circle.
  final Widget leading;
  final String title;
  final String? subtitle;

  /// One trailing qualifier under the subtitle: a verified-purchase pill, a
  /// driver's star rating. Omitted when there is nothing true to say, and
  /// responsible for its own top spacing (see the build method).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(Constants.paddingSizeSmall + 2),
      decoration: BoxDecoration(
        color: context.scaffoldBackground,
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        border: Border.all(color: context.textLight.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: Constants.paddingSizeSmall + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: context.textPrimary,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitleText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // No gap here on purpose: a badge carries its own top
                // spacing, so one that renders nothing (a driver with no
                // ratings yet) collapses completely rather than leaving a
                // stray band of air under the subtitle.
                if (badge != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: badge,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The sheet's own title. Centred, because the dismiss control has been moved
/// out to the corner strip above and is no longer competing for the row.
class ReviewSheetTitle extends StatelessWidget {
  const ReviewSheetTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: poppinsBold.copyWith(
        fontSize: Constants.fontSizeExtraLarge,
        color: context.textPrimary,
      ),
    );
  }
}

/// Hairline under the pinned header. Its job is to say "there is more below
/// this, and it moves" — without it the pinned block and the scrolling form
/// read as one surface that has mysteriously stopped scrolling at the top.
class ReviewSheetDivider extends StatelessWidget {
  const ReviewSheetDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.textLight.withValues(alpha: 0.15),
    );
  }
}
