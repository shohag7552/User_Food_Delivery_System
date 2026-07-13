import 'package:appwrite_user_app/app/controllers/localization_controller.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: ColorResource.primaryDark,
        foregroundColor: ColorResource.textWhite,
        elevation: 0,
        title: Text(
          'language'.tr,
          style: poppinsBold.copyWith(
            color: ColorResource.textWhite,
            fontSize: Constants.fontSizeLarge,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: ColorResource.primaryGradient),
        ),
      ),
      body: GetBuilder<LocalizationController>(
        builder: (controller) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header banner
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(gradient: ColorResource.primaryGradient),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'choose_your_language'.tr,
                        style: poppinsBold.copyWith(
                          color: ColorResource.textWhite,
                          fontSize: Constants.fontSizeOverLarge,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'choose_your_language_to_proceed'.tr,
                        style: poppinsRegular.copyWith(
                          color: ColorResource.textWhite.withValues(alpha: 0.8),
                          fontSize: Constants.fontSizeDefault,
                        ),
                      ),
                    ],
                  ),
                ),

                // Decorative arc
                CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 24),
                  painter: _ArcPainter(color: ColorResource.primaryLight),
                ),

                const SizedBox(height: 8),

                // Language list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: controller.languages.length,
                    itemBuilder: (context, index) {
                      final language = controller.languages[index];
                      final isSelected = controller.selectedLanguageIndex == index;
                      return _LanguageCard(
                        language: language,
                        isSelected: isSelected,
                        onTap: () => _onLanguageTapped(controller, index, language),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onLanguageTapped(LocalizationController controller, int index, LanguageModel language) {
    controller.setSelectLanguageIndex(index);
    controller.setLanguage(
      Locale(language.languageCode!, language.countryCode),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) context.pop();
    });
  }
}

// ── Language Card ─────────────────────────────────────────────────────────────

class _LanguageCard extends StatelessWidget {
  final LanguageModel language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? ColorResource.primaryDark.withValues(alpha: 0.06) : context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        border: Border.all(
          color: isSelected ? ColorResource.primaryDark : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: ColorResource.primaryDark.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : ColorResource.customShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Flag image
                Container(
                  width: 52,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      language.imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, _) => Container(
                        color: ColorResource.primaryLight.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.language,
                          color: ColorResource.primaryDark,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Language name
                Expanded(
                  child: Text(
                    language.languageName ?? '',
                    style: (isSelected ? poppinsBold : poppinsMedium).copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: isSelected ? ColorResource.primaryDark : context.textPrimary,
                    ),
                  ),
                ),

                // Selected indicator
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? Container(
                          key: const ValueKey('check'),
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: ColorResource.primaryDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: ColorResource.textWhite,
                            size: 16,
                          ),
                        )
                      : const SizedBox(key: ValueKey('empty'), width: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Arc Painter ───────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final Color color;
  const _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..lineTo(0, 0)
      ..quadraticBezierTo(size.width / 2, size.height * 2, size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.color != color;
}
