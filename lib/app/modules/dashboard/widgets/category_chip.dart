import 'package:flutter/material.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';

class CategoryChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    this.icon,
    this.imageUrl,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? ColorResource.primaryGradient
                : null,
            color: widget.isSelected ? null : ColorResource.cardBackground,
            borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
            border: widget.isSelected
                ? null
                : Border.all(
                    color: ColorResource.textLight.withOpacity(0.3),
                    width: 1.5,
                  ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: ColorResource.primaryMedium.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: ColorResource.shadowLight,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon or Image
              if (widget.icon != null)
                Icon(
                  widget.icon,
                  size: 20,
                  color: widget.isSelected
                      ? ColorResource.textWhite
                      : ColorResource.textSecondary,
                ),
              if (widget.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(Constants.radiusSmall),
                  child: Image.network(
                    widget.imageUrl!,
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.category,
                        size: 20,
                        color: widget.isSelected
                            ? ColorResource.textWhite
                            : ColorResource.textSecondary,
                      );
                    },
                  ),
                ),
              if (widget.icon != null || widget.imageUrl != null)
                const SizedBox(width: 8),
              // Label
              Text(
                widget.label,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: widget.isSelected
                      ? ColorResource.textWhite
                      : ColorResource.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
