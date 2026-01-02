import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';

/// A reusable custom text field widget with consistent styling across the app
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool obscureText;
  final String? hintText;
  final Widget? suffixIcon;
  final bool enabled;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final String? initialValue;
  final TextCapitalization? textCapitalization;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.icon,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    this.hintText,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.initialValue,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      // Only use initialValue when controller is not provided
      // Flutter's TextFormField throws an assertion error if both are used
      initialValue: controller == null ? initialValue : null,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      obscureText: obscureText,
      enabled: enabled,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      style: poppinsRegular.copyWith(fontSize: 15),
      textCapitalization: textCapitalization!,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: poppinsRegular.copyWith(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        hintStyle: poppinsRegular.copyWith(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        prefixIcon: icon != null 
            ? Icon(icon, color: Theme.of(context).primaryColor)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
