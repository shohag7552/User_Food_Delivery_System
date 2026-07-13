import 'package:appwrite_user_app/app/common/widgets/auth_dialog.dart';
import 'package:appwrite_user_app/app/controllers/favorites_controller.dart';
import 'package:appwrite_user_app/app/helper/session_manager.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoriteButton extends StatelessWidget {
  final ProductModel product;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;

  const FavoriteButton({
    super.key,
    required this.product,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FavoritesController>(
      builder: (controller) {
        final isFavorite = controller.isFavorite(product.id);
        final isLoading = controller.isToggleLoading(product.id);

        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  // Favouriting requires an account — prompt guests to sign in.
                  if (!isUserLoggedIn()) {
                    AuthFlow.openLogin(context);
                    return;
                  }
                  controller.toggleFavorite(product);
                },
          child: Container(
            padding: EdgeInsets.all(size * 0.4),
            decoration: BoxDecoration(
              color: backgroundColor ?? ColorResource.textWhite,
              shape: BoxShape.circle,
            
            ),
            child: isLoading
                ? SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        activeColor ?? ColorResource.primaryDark,
                      ),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_outline,
                      key: ValueKey(isFavorite),
                      size: size,
                      color: isFavorite
                          ? (activeColor ?? ColorResource.error)
                          : (inactiveColor ?? context.textLight),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
