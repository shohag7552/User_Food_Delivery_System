import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six digit boxes backed by ONE hidden text field.
///
/// A single field (rather than six) keeps paste, SMS/email one-time-code
/// autofill, backspace and screen readers working the way the platform
/// expects; the boxes only render what it holds.
class ResetCodeField extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String> onCompleted;

  const ResetCodeField({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.length = 6,
    this.hasError = false,
    this.enabled = true,
  });

  @override
  State<ResetCodeField> createState() => _ResetCodeFieldState();
}

class _ResetCodeFieldState extends State<ResetCodeField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant ResetCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Disabled while a code is checked; after a wrong code, put the cursor
    // straight back so the user can retype.
    if (!oldWidget.enabled && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final focused = _focusNode.hasFocus;

    return Stack(
      alignment: Alignment.center,
      children: [
        // The real input: invisible but covering the boxes, so taps,
        // long-press paste, IME and autofill all reach it natively.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: widget.length,
              showCursor: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                if (value.length == widget.length) widget.onCompleted(value);
              },
            ),
          ),
        ),
        // Boxes always run left-to-right: a code is read digit by digit in
        // the same order in every language. Taps pass through to the field.
        IgnorePointer(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: Constants.paddingSizeSmall),
                  Expanded(
                    child: _box(
                      context,
                      digit: i < code.length ? code[i] : '',
                      active:
                          focused &&
                          widget.enabled &&
                          (i == code.length ||
                              (i == widget.length - 1 &&
                                  code.length == widget.length)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _box(
    BuildContext context, {
    required String digit,
    required bool active,
  }) {
    final Color borderColor;
    if (widget.hasError) {
      borderColor = ColorResource.error;
    } else if (active) {
      borderColor = ColorResource.primaryDark;
    } else {
      borderColor = context.textSecondary.withValues(alpha: 0.25);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        border: Border.all(color: borderColor, width: active ? 1.6 : 1),
      ),
      child: Text(
        digit,
        style: poppinsBold.copyWith(
          fontSize: Constants.fontSizeExtraLarge + 2,
          color: context.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
