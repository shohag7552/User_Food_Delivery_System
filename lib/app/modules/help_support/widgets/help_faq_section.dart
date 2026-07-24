import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Static, translated FAQ rendered as a grouped card of expandable tiles.
/// The question/answer keys live in the language files so the copy stays
/// localised without any backend round-trip.
class HelpFaqSection extends StatelessWidget {
  const HelpFaqSection({super.key});

  static const List<(String, String)> _faqs = [
    ('faq_q1', 'faq_a1'),
    ('faq_q2', 'faq_a2'),
    ('faq_q3', 'faq_a3'),
    ('faq_q4', 'faq_a4'),
    ('faq_q5', 'faq_a5'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        child: Theme(
          // Neutralise the default ExpansionTile divider/splash so the tiles
          // read as one cohesive card.
          data: theme.copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: Column(
            children: [
              for (int i = 0; i < _faqs.length; i++) ...[
                _FaqTile(
                  question: _faqs[i].$1.tr,
                  answer: _faqs[i].$2.tr,
                ),
                if (i != _faqs.length - 1)
                  Divider(
                    height: 1,
                    indent: Constants.paddingSizeDefault,
                    endIndent: Constants.paddingSizeDefault,
                    color: theme.dividerColor
                        .withValues(alpha: isDark ? 0.45 : 0.3),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(
        horizontal: Constants.paddingSizeDefault,
        vertical: Constants.paddingSizeExtraSmall,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
        Constants.paddingSizeDefault,
        0,
        Constants.paddingSizeDefault,
        Constants.paddingSizeDefault,
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      iconColor: ColorResource.primaryDark,
      collapsedIconColor:
          isDark ? Colors.white54 : ColorResource.primaryMedium,
      title: Text(
        question,
        style: poppinsMedium.copyWith(
          fontSize: Constants.fontSizeDefault,
          color: isDark ? Colors.white : context.textPrimary,
        ),
      ),
      children: [
        Text(
          answer,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeSmall,
            height: 1.6,
            color: isDark ? Colors.white70 : context.textSecondary,
          ),
        ),
      ],
    );
  }
}
