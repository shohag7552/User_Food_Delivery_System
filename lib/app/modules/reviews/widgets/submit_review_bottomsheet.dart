import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/review_controller.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubmitReviewBottomSheet extends StatefulWidget {
  final String productId;
  final String productName;
  final bool verifiedPurchase;

  const SubmitReviewBottomSheet({
    super.key,
    required this.productId,
    required this.productName,
    this.verifiedPurchase = false,
  });

  @override
  State<SubmitReviewBottomSheet> createState() =>
      _SubmitReviewBottomSheetState();

  static Future<bool?> show(
    BuildContext context, {
    required String productId,
    String? userId,
    String? userName,
    String productName = '',
    bool verifiedPurchase = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubmitReviewBottomSheet(
        productId: productId,
        productName: productName,
        verifiedPurchase: verifiedPurchase,
      ),
    );
  }
}

class _SubmitReviewBottomSheetState extends State<SubmitReviewBottomSheet> {
  int _rating = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _rating > 0 && _commentController.text.trim().isNotEmpty;
  }

  Future<void> _submitReview() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = await Get.find<AuthController>().getUserId();
      final userName = await Get.find<AuthController>().getUserName() ?? 'User';

      if (userId == null) {
        Get.snackbar('Error', 'Please login to submit a review');
        return;
      }

      final success = await Get.find<ReviewController>().submitReview(
        productId: widget.productId,
        userId: userId,
        userName: userName,
        rating: _rating,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
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
    return Container(
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Constants.radiusExtraLarge),
          topRight: Radius.circular(Constants.radiusExtraLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Write a Review',
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeExtraLarge,
                            color: ColorResource.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.productName,
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: ColorResource.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: ColorResource.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Rating selector
              Text(
                'Your Rating *',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: InteractiveRatingStars(
                  rating: _rating,
                  onRatingChanged: (rating) {
                    setState(() => _rating = rating);
                  },
                  size: 40,
                ),
              ),
              if (_rating > 0) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _getRatingText(_rating),
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Title (optional)
              Text(
                'Review Title (Optional)',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Summarize your experience',
                  hintStyle: poppinsRegular.copyWith(
                    color: ColorResource.textLight,
                  ),
                  filled: true,
                  fillColor: ColorResource.scaffoldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Constants.radiusDefault),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLength: 100,
              ),

              const SizedBox(height: 16),

              // Comment
              Text(
                'Your Review *',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts about this product...',
                  hintStyle: poppinsRegular.copyWith(
                    color: ColorResource.textLight,
                  ),
                  filled: true,
                  fillColor: ColorResource.scaffoldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Constants.radiusDefault),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 5,
                maxLength: 500,
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_canSubmit && !_isSubmitting) ? _submitReview : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: ColorResource.primaryDark,
                    disabledBackgroundColor: ColorResource.textLight.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Constants.radiusLarge),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ColorResource.textWhite,
                            ),
                          ),
                        )
                      : Text(
                          'Submit Review',
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: ColorResource.textWhite,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
