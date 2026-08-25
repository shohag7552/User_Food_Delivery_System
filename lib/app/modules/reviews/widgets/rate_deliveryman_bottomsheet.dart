import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/rive_rating_stars.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/deliveryman_review_controller.dart';
import 'package:appwrite_user_app/app/models/deliveryman_review_model.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/deliveryman_rating_badge.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/review_sheet_header.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Rates the person who delivered one order.
///
/// Stars are the only required input: a delivery is a two-minute interaction,
/// and demanding prose is what turns a rating people would happily give into
/// one they abandon. The chips exist so a customer who *does* want to say
/// something can do it with a tap instead of a paragraph.
class RateDeliverymanBottomSheet extends StatefulWidget {
  const RateDeliverymanBottomSheet({
    super.key,
    required this.order,
    this.existingReview,
    this.initialRating = 0,
  });

  final OrderModel order;

  /// Set when the customer is editing a rating they already left.
  final DeliverymanReviewModel? existingReview;

  /// Star the customer already tapped on the card behind the sheet. It seeds
  /// the form — it is not a submission, so they can still change it here.
  final int initialRating;

  static Future<bool?> show(
    BuildContext context, {
    required OrderModel order,
    DeliverymanReviewModel? existingReview,
    int initialRating = 0,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Caps the sheet short of the top edge: even with the keyboard up, the
      // driver being rated stays on screen.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      builder: (_) => RateDeliverymanBottomSheet(
        order: order,
        existingReview: existingReview,
        initialRating: initialRating,
      ),
    );
  }

  @override
  State<RateDeliverymanBottomSheet> createState() =>
      _RateDeliverymanBottomSheetState();
}

class _RateDeliverymanBottomSheetState
    extends State<RateDeliverymanBottomSheet> {
  static const double _avatarSize = 52;

  final TextEditingController _commentController = TextEditingController();
  final DeliverymanReviewController _controller =
      Get.find<DeliverymanReviewController>();

  late int _rating = widget.existingReview?.rating ?? widget.initialRating;
  late final Set<String> _selectedTags = {...?widget.existingReview?.tags};
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    _commentController.text = widget.existingReview?.comment ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Star wording. A number alone leaves the customer guessing whether 3 means
  /// "fine" or "bad"; the label removes the guess before they commit.
  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'rating_very_bad'.tr;
      case 2:
        return 'rating_bad'.tr;
      case 3:
        return 'rating_okay'.tr;
      case 4:
        return 'rating_good'.tr;
      case 5:
        return 'rating_excellent'.tr;
      default:
        return '';
    }
  }

  Color get _ratingColor {
    if (_rating <= 2) return ColorResource.error;
    if (_rating == 3) return ColorResource.warning;
    return ColorResource.success;
  }

  Future<void> _submit() async {
    if (_rating == 0 || _isSubmitting) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      final authController = Get.find<AuthController>();
      final userId = await authController.getUserId();
      if (userId == null) {
        if (mounted) Navigator.pop(context, false);
        return;
      }

      final success = await _controller.submitReview(
        order: widget.order,
        userId: userId,
        userName: await authController.getUserName() ?? 'User',
        rating: _rating,
        comment: _commentController.text,
        // Chips are scoped to the score, so a rating changed from 5 to 2 after
        // tagging must not ship "polite" alongside two stars.
        tags: _selectedTags
            .where(_controller.tagsForRating(_rating).contains)
            .toList(),
      );

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryman = widget.order.deliveryman;
    final availableTags = _controller.tagsForRating(_rating);

    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Constants.radiusExtraLarge),
          topRight: Radius.circular(Constants.radiusExtraLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReviewSheetTopBar(onClose: () => Navigator.pop(context)),
            _buildHeader(context, deliveryman),
            const ReviewSheetDivider(),
            // Only the form scrolls — who is being rated stays pinned above
            // it, so the customer never loses that context to the keyboard.
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: Constants.paddingSizeLarge,
                  right: Constants.paddingSizeLarge,
                  top: Constants.paddingSizeLarge,
                  bottom:
                      Constants.paddingSizeLarge +
                      MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStars(context),
                    // The rest of the form only makes sense once a score exists,
                    // so it grows in rather than sitting there greyed out.
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _rating == 0
                          ? const SizedBox(width: double.infinity)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(
                                  height: Constants.paddingSizeLarge,
                                ),
                                _buildTags(context, availableTags),
                                const SizedBox(
                                  height: Constants.paddingSizeLarge,
                                ),
                                _buildCommentField(context),
                              ],
                            ),
                    ),
                    const SizedBox(height: Constants.paddingSizeLarge),
                    _buildSubmitButton(context),
                    const SizedBox(height: Constants.paddingSizeSmall),
                    Text(
                      'delivery_rating_privacy_note'.tr,
                      textAlign: TextAlign.center,
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeExtraSmall,
                        color: context.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pinned above the form: what is being asked, and who it is being asked
  /// about. The driver is quoted as a subject card rather than dressed up as a
  /// banner — the customer is answering about a person, not reading an advert.
  Widget _buildHeader(BuildContext context, DeliverymanInfo? deliveryman) {
    final name = deliveryman?.name.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Constants.paddingSizeLarge,
        0,
        Constants.paddingSizeLarge,
        Constants.paddingSizeDefault,
      ),
      child: Column(
        children: [
          ReviewSheetTitle(title: 'how_was_your_delivery'.tr),
          const SizedBox(height: Constants.paddingSizeDefault),
          ReviewSubjectCard(
            leading: _buildAvatar(context, deliveryman),
            title: name.isEmpty ? 'your_delivery_partner'.tr : name,
            subtitle: '#${widget.order.orderNumber}',
            // The driver's public score, where they have one. It tells the
            // customer their rating joins a body of them rather than standing
            // alone as a verdict on one person.
            badge: DeliverymanRatingBadge(
              driverId: _controller.resolveDriverId(widget.order),
            ),
          ),
        ],
      ),
    );
  }

  /// The driver's photo where the store has one, a courier glyph otherwise —
  /// never an initial, which at this size reads as a placeholder for a name
  /// that failed to load.
  Widget _buildAvatar(BuildContext context, DeliverymanInfo? deliveryman) {
    final image = deliveryman?.image?.trim() ?? '';

    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorResource.primaryDark.withValues(alpha: 0.06),
        border: Border.all(
          color: ColorResource.primaryDark.withValues(alpha: 0.18),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: image.isNotEmpty
          ? CustomNetworkImage(
              image: image,
              width: _avatarSize,
              height: _avatarSize,
              fit: BoxFit.cover,
            )
          : Icon(
              Icons.delivery_dining,
              color: ColorResource.primaryDark,
              size: 26,
            ),
    );
  }

  Widget _buildStars(BuildContext context) {
    return Column(
      children: [
        Center(
          child: RiveRatingStars(
            rating: _rating,
            onRatingChanged: (rating) => setState(() => _rating = rating),
          ),
        ),
        const SizedBox(height: Constants.paddingSizeSmall),
        // Reserves its own height so picking a star does not shift the stars
        // themselves under the finger that just tapped them.
        SizedBox(
          height: 24,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _rating == 0
                ? Text(
                    'tap_a_star_to_rate'.tr,
                    key: const ValueKey('hint'),
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: context.textLight,
                    ),
                  )
                : Container(
                    key: ValueKey(_rating),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Constants.paddingSizeSmall,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _ratingColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        Constants.radiusExtraLarge,
                      ),
                    ),
                    child: Text(
                      _ratingLabel,
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: _ratingColor,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTags(BuildContext context, List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _rating >= 4 ? 'what_went_well'.tr : 'what_went_wrong'.tr,
          style: poppinsMedium.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeSmall),
        Wrap(
          spacing: Constants.paddingSizeSmall - 2,
          runSpacing: Constants.paddingSizeSmall - 2,
          children: tags
              .map(
                (tag) => _TagChip(
                  label: tag.tr,
                  isSelected: _selectedTags.contains(tag),
                  accent: _ratingColor,
                  onTap: () => setState(() {
                    if (!_selectedTags.remove(tag)) _selectedTags.add(tag);
                  }),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCommentField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'add_a_note_optional'.tr,
          style: poppinsMedium.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeSmall),
        TextField(
          controller: _commentController,
          maxLines: 3,
          maxLength: 500,
          textInputAction: TextInputAction.newline,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: _rating >= 4
                ? 'delivery_comment_hint_positive'.tr
                : 'delivery_comment_hint_negative'.tr,
            hintStyle: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: context.textLight,
            ),
            filled: true,
            fillColor: context.scaffoldBackground,
            counterText: '',
            contentPadding: const EdgeInsets.all(Constants.paddingSizeDefault),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
              borderSide: BorderSide(
                color: ColorResource.primaryDark.withValues(alpha: 0.4),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final isEnabled = _rating > 0 && !_isSubmitting;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isEnabled ? _submit : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: ColorResource.primaryDark,
          disabledBackgroundColor: context.textLight.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorResource.textWhite,
                  ),
                ),
              )
            : Text(
                _isEditing ? 'update_rating'.tr : 'submit_rating'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textWhite,
                ),
              ),
      ),
    );
  }
}

/// A single tappable feedback chip. Selection is carried by fill *and* a check
/// glyph rather than colour alone, so it still reads for a colour-blind user.
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: Constants.paddingSizeDefault - 3,
            vertical: Constants.paddingSizeSmall - 2,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.12)
                : context.scaffoldBackground,
            borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
            border: Border.all(
              color: isSelected
                  ? accent.withValues(alpha: 0.6)
                  : context.textLight.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_rounded, size: 14, color: accent),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: isSelected ? accent : context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
