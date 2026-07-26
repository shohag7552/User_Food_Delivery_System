import 'package:appwrite_user_app/app/controllers/localization_controller.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageSelector extends StatelessWidget {
  final bool isDialog;
  const LanguageSelector({super.key, this.isDialog = false});

  static void show(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth >= 900;

    if (isWeb) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          backgroundColor: context.scaffoldBackground,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'choose_your_language'.tr,
                        style: poppinsBold.copyWith(
                          fontSize: 18,
                          color: context.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const Flexible(
                  child: LanguageSelector(isDialog: true),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      Get.bottomSheet(
        Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'choose_your_language'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: 18,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const Divider(height: 1),
                const Flexible(
                  child: LanguageSelector(isDialog: false),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (controller) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isDialog ? 12 : 16,
            vertical: 8,
          ),
          itemCount: controller.languages.length,
          itemBuilder: (context, index) {
            final language = controller.languages[index];
            final isSelected = controller.selectedLanguageIndex == index;
            return _LanguageCard(
              language: language,
              isSelected: isSelected,
              onTap: () {
                controller.setSelectLanguageIndex(index);
                controller.setLanguage(
                  Locale(language.languageCode, language.countryCode),
                );
                Future.delayed(const Duration(milliseconds: 250), () {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                });
              },
            );
          },
        );
      },
    );
  }
}

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
                      language.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, _) => Container(
                        color: ColorResource.primaryLight.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.language,
                          color: ColorResource.primaryDark,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    language.languageName,
                    style: (isSelected ? poppinsBold : poppinsMedium).copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: isSelected ? ColorResource.primaryDark : context.textPrimary,
                    ),
                  ),
                ),
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
