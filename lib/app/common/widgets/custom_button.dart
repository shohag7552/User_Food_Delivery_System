import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
class CustomButton extends StatelessWidget {
  final Function()? onPressed;
  final bool isLoading;
  final String buttonText;
  final double? height;
  final double? elevation;
  const CustomButton({super.key, required this.onPressed, this.isLoading = false, required this.buttonText, this.height = 56, this.elevation = 4});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003B55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: elevation,
          shadowColor: const Color(0xFF003B55).withOpacity(0.5),
        ),
        child: isLoading
            ? SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        )
            : Text(buttonText,
          style: poppinsBold.copyWith(
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
