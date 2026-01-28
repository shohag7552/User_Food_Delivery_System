import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showRating;
  final int? reviewCount;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.activeColor,
    this.inactiveColor,
    this.showRating = false,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < rating.floor()
                ? Icons.star
                : (index < rating
                    ? Icons.star_half
                    : Icons.star_border),
            size: size,
            color: index < rating
                ? (activeColor ?? Colors.amber)
                : (inactiveColor ?? ColorResource.textLight),
          );
        }),
        if (showRating) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              color: ColorResource.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size * 0.75,
              color: ColorResource.textLight,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveRatingStars extends StatefulWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const InteractiveRatingStars({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40,
  });

  @override
  State<InteractiveRatingStars> createState() => _InteractiveRatingStarsState();
}

class _InteractiveRatingStarsState extends State<InteractiveRatingStars> {
  int _hoverRating = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isActive = starIndex <= (_hoverRating > 0 ? _hoverRating : widget.rating);

        return GestureDetector(
          onTap: () => widget.onRatingChanged(starIndex),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoverRating = starIndex),
            onExit: (_) => setState(() => _hoverRating = 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                isActive ? Icons.star : Icons.star_border,
                size: widget.size,
                color: isActive ? Colors.amber : ColorResource.textLight,
              ),
            ),
          ),
        );
      }),
    );
  }
}
