import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/rive_rating_stars.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/review_controller.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/review_sheet_header.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Writes a review for one product the customer bought.
///
/// The whole sheet scrolls and carries the keyboard inset, so focusing either
/// text field lifts it into view instead of overflowing the sheet — a review
/// form that breaks the moment you type in it is a review nobody finishes.
class SubmitReviewBottomSheet extends StatefulWidget {
  final String? orderId;
  final String productId;
  final String productName;
  final String productImage;
  final bool verifiedPurchase;

  /// Sheet on a phone, dialog on desktop web. Only affects chrome — corners,
  /// grabber, safe-area inset — never the form itself.
  final ReviewSheetMode mode;

  const SubmitReviewBottomSheet({
    super.key,
    this.orderId,
    required this.productId,
    required this.productName,
    this.productImage = '',
    this.verifiedPurchase = false,
    this.mode = ReviewSheetMode.sheet,
  });

  @override
  State<SubmitReviewBottomSheet> createState() =>
      _SubmitReviewBottomSheetState();

  static Future<bool?> show(
    BuildContext context, {
    String? orderId,
    required String productId,
    String? userId,
    String? userName,
    String productName = '',
    String productImage = '',
    bool verifiedPurchase = false,
  }) {
    return showReviewSurface(
      context: context,
      builder: (mode) => SubmitReviewBottomSheet(
        orderId: orderId,
        productId: productId,
        productName: productName,
        productImage: productImage,
        verifiedPurchase: verifiedPurchase,
        mode: mode,
      ),
    );
  }
}

class _SubmitReviewBottomSheetState extends State<SubmitReviewBottomSheet> {
  static const double _thumbnailSize = 56;
  static const int _titleMaxLength = 100;
  static const int _commentMaxLength = 500;

  int _rating = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // The submit button and the counter both depend on what is typed, so the
    // sheet has to hear every keystroke rather than only rebuilds.
    _commentController.addListener(_onCommentChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onCommentChanged);
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onCommentChanged() => setState(() {});

  bool get _canSubmit =>
      _rating > 0 && _commentController.text.trim().isNotEmpty;

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

  Future<void> _submitReview() async {
    if (!_canSubmit || _isSubmitting) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      final authController = Get.find<AuthController>();
      final userId = await authController.getUserId();

      if (userId == null) {
        Get.snackbar('error'.tr, 'please_login_to_submit_review'.tr);
        return;
      }

      final title = _titleController.text.trim();
      final success = await Get.find<ReviewController>().submitReview(
        orderId: widget.orderId,
        productId: widget.productId,
        userId: userId,
        userName: await authController.getUserName() ?? 'User',
        rating: _rating,
        title: title.isEmpty ? null : title,
        comment: _commentController.text.trim(),
        verifiedPurchase: widget.verifiedPurchase,
      );

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDialog = widget.mode.isDialog;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        // A dialog floats, so it is rounded all the way round; a sheet is
        // anchored to the bottom edge and only rounds the corners that leave it.
        borderRadius: isDialog
            ? BorderRadius.circular(Constants.radiusExtraLarge)
            : const BorderRadius.only(
                topLeft: Radius.circular(Constants.radiusExtraLarge),
                topRight: Radius.circular(Constants.radiusExtraLarge),
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        // The dialog's inset padding already clears the system bars; adding the
        // safe area on top of it would double the gap.
        top: false,
        bottom: !isDialog,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReviewSheetTopBar(
              mode: widget.mode,
              onClose: () => Navigator.pop(context),
            ),
            _buildHeader(context),
            const ReviewSheetDivider(),
            // Only the form scrolls — the product being reviewed stays pinned
            // above it, so the customer never loses track of what they are
            // rating while the keyboard is up.
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
                    const SizedBox(height: Constants.paddingSizeLarge),
                    _buildTitleField(context),
                    const SizedBox(height: Constants.paddingSizeDefault),
                    _buildCommentField(context),
                    const SizedBox(height: Constants.paddingSizeLarge),
                    _buildSubmitButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pinned above the form: what the sheet is for, and what is being reviewed.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Constants.paddingSizeLarge,
        0,
        Constants.paddingSizeLarge,
        Constants.paddingSizeDefault,
      ),
      child: Column(
        children: [
          ReviewSheetTitle(title: 'write_a_review'.tr),
          const SizedBox(height: Constants.paddingSizeDefault),
          ReviewSubjectCard(
            leading: _buildThumbnail(context),
            title: widget.productName.isEmpty
                ? 'product'.tr
                : widget.productName,
            badge: widget.verifiedPurchase
                ? _buildVerifiedBadge(context)
                : null,
          ),
        ],
      ),
    );
  }

  /// The product's own picture where there is one; a neutral placeholder tile
  /// otherwise, so the card keeps its shape either way.
  Widget _buildThumbnail(BuildContext context) {
    return Container(
      width: _thumbnailSize,
      height: _thumbnailSize,
      decoration: BoxDecoration(
        color: ColorResource.primaryDark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        border: Border.all(
          color: ColorResource.primaryDark.withValues(alpha: 0.12),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.productImage.isNotEmpty
          ? CustomNetworkImage(
              image: widget.productImage,
              width: _thumbnailSize,
              height: _thumbnailSize,
              fit: BoxFit.cover,
            )
          : Icon(
              Icons.shopping_bag_outlined,
              size: 24,
              color: ColorResource.primaryDark,
            ),
    );
  }

  /// Says why this review will carry weight. Shown only when the order proves
  /// the purchase, so it never claims something the data cannot back.
  Widget _buildVerifiedBadge(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Constants.paddingSizeExtraSmall - 1),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Constants.paddingSizeSmall - 2,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: ColorResource.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_rounded,
              size: 13,
              color: ColorResource.success,
            ),
            const SizedBox(width: 4),
            Text(
              'verified_purchase'.tr,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeExtraSmall,
                color: ColorResource.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Get.isDarkMode ? Colors.blueGrey : null,
            borderRadius: BorderRadius.circular(Constants.radiusDefault),
          ),
          child: Center(
            child: RiveRatingStars(
              rating: _rating,
              onRatingChanged: (rating) => setState(() => _rating = rating),
            ),
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

  Widget _buildTitleField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'review_title'.tr, isRequired: false),
        const SizedBox(height: Constants.paddingSizeSmall),
        TextField(
          controller: _titleController,
          maxLength: _titleMaxLength,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textPrimary,
          ),
          decoration: _fieldDecoration(
            context,
            hint: 'summarize_your_experience'.tr,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentField(BuildContext context) {
    final length = _commentController.text.characters.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFieldLabel(
                context,
                'your_review'.tr,
                isRequired: true,
              ),
            ),
            // A live count beats a counter that only appears once you are near
            // the cap — the limit is visible before it starts truncating.
            Text(
              '$length/$_commentMaxLength',
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeExtraSmall,
                color: length >= _commentMaxLength
                    ? ColorResource.error
                    : context.textLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: Constants.paddingSizeSmall),
        TextField(
          controller: _commentController,
          maxLines: 4,
          minLines: 3,
          maxLength: _commentMaxLength,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textPrimary,
          ),
          decoration: _fieldDecoration(context, hint: 'share_your_thoughts'.tr),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(
    BuildContext context,
    String label, {
    required bool isRequired,
  }) {
    return RichText(
      text: TextSpan(
        text: label,
        style: poppinsMedium.copyWith(
          fontSize: Constants.fontSizeDefault,
          color: context.textPrimary,
        ),
        children: [
          TextSpan(
            text: isRequired ? ' *' : ' (${'optional'.tr})',
            style: poppinsRegular.copyWith(
              fontSize: isRequired
                  ? Constants.fontSizeDefault
                  : Constants.fontSizeSmall,
              color: isRequired ? ColorResource.error : context.textLight,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: poppinsRegular.copyWith(
        fontSize: Constants.fontSizeSmall,
        color: context.textLight,
      ),
      filled: true,
      fillColor: context.scaffoldBackground,
      // The count above the field already carries this; the built-in counter
      // would repeat it and add a stray line of height under every field.
      counterText: '',
      contentPadding: const EdgeInsets.all(Constants.paddingSizeDefault),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        borderSide: BorderSide(
          color: ColorResource.primaryDark.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: (_canSubmit && !_isSubmitting) ? _submitReview : null,
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
                'submit_review'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textWhite,
                ),
              ),
      ),
    );
  }
}
