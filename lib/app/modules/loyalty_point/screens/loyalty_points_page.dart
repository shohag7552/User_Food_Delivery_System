import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/loyalty_controller.dart';
import 'package:appwrite_user_app/app/controllers/profile_controller.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/models/loyalty_history_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LoyaltyPointsPage extends StatefulWidget {
  const LoyaltyPointsPage({super.key});

  @override
  State<LoyaltyPointsPage> createState() => _LoyaltyPointsPageState();
}

class _LoyaltyPointsPageState extends State<LoyaltyPointsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<LoyaltyController>().initializeLoyalty();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Loyalty Points',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeExtraLarge,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorResource.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GetBuilder<LoyaltyController>(
        builder: (loyaltyController) {
          return GetBuilder<ProfileController>(
            builder: (profileController) {
              final user = profileController.userProfile;
              final totalPoints = user?.loyaltyPoints ?? 0;

              return RefreshIndicator(
                onRefresh: loyaltyController.initializeLoyalty,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(
                        context: context,
                        userName: user?.name,
                        totalPoints: totalPoints,
                        walletConversionRate:
                            loyaltyController.walletConversionRate,
                        isConverting: loyaltyController.isConverting,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Points activity',
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeLarge,
                          color: isDark
                              ? Colors.white
                              : ColorResource.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track how points are earned and redeemed across your account.',
                        style: poppinsRegular.copyWith(
                          color: isDark
                              ? Colors.white70
                              : ColorResource.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (loyaltyController.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (loyaltyController.history.isEmpty)
                        _buildEmptyState(context)
                      else
                        ...loyaltyController.history.map(
                          (transaction) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTransactionCard(context, transaction),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String? userName,
    required int totalPoints,
    required double walletConversionRate,
    required bool isConverting,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE25757), Color(0xFFC92A2A), Color(0xFF7F1D1D)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryDark.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '1 point = ${CurrencyHelper.formatAmount(walletConversionRate)}',
                  style: poppinsMedium.copyWith(
                    color: Colors.white,
                    fontSize: Constants.fontSizeSmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            userName?.isNotEmpty == true
                ? '$userName, your total points'
                : 'Your total loyalty points',
            style: poppinsMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: Constants.fontSizeDefault,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            NumberFormat.decimalPattern().format(totalPoints),
            style: poppinsBold.copyWith(
              color: Colors.white,
              fontSize: 36,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Convert your points into wallet balance whenever you are ready.',
            style: poppinsRegular.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: Constants.fontSizeDefault,
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            onPressed: totalPoints == 0 ? null : _handleConvertToWallet,
            buttonText: 'Convert to Wallet',
            height: 52,
            elevation: 0,
            isLoading: isConverting,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    LoyaltyHistoryModel transaction,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEarned = transaction.isEarned;
    final accentColor = isEarned
        ? ColorResource.success
        : ColorResource.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B2D) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEarned ? Icons.add_card_rounded : Icons.sync_alt_rounded,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: isDark ? Colors.white : ColorResource.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: poppinsRegular.copyWith(
                    color: isDark
                        ? Colors.white70
                        : ColorResource.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat(
                    'dd MMM yyyy, hh:mm a',
                  ).format(transaction.createdAt),
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: isDark ? Colors.white54 : ColorResource.textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isEarned ? '+' : '-'}${transaction.points}',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'points',
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: isDark ? Colors.white54 : ColorResource.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleConvertToWallet() {
    final pointsController = TextEditingController();
    final loyaltyController = Get.find<LoyaltyController>();
    final totalPoints =
        Get.find<ProfileController>().userProfile?.loyaltyPoints ?? 0;
    final walletConversionRate = loyaltyController.walletConversionRate;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final enteredPoints =
                int.tryParse(pointsController.text.trim()) ?? 0;
            final validationMessage = _getConversionValidation(
              pointsController.text.trim(),
            );
            final convertedAmount = CurrencyHelper.formatWithSeparators(
              enteredPoints * walletConversionRate,
            );

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Convert loyalty points',
                style: poppinsBold.copyWith(fontSize: 20),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available points: ${NumberFormat.decimalPattern().format(totalPoints)}',
                      style: poppinsMedium.copyWith(
                        color: ColorResource.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Conversion rate: 1 point = ${CurrencyHelper.formatAmount(walletConversionRate)}',
                      style: poppinsRegular.copyWith(
                        color: ColorResource.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofocus: true,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Enter points to convert',
                        hintText: 'e.g. 100',
                        errorText: validationMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: ColorResource.primaryDark,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorResource.primaryDark.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You will receive',
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: ColorResource.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            convertedAmount,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: ColorResource.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: poppinsMedium.copyWith(
                      color: ColorResource.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: CustomButton(
                    onPressed: validationMessage != null
                        ? null
                        : () async {
                            final converted = await loyaltyController
                                .convertPointsToWallet(enteredPoints);
                            if (converted) {
                              Get.back();
                              customToster('Conversion successful ${NumberFormat.decimalPattern().format(enteredPoints)} points converted to $convertedAmount.');
                            }
                          },
                    buttonText: 'Convert',
                    height: 46,
                    elevation: 0,
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => pointsController.dispose());
  }

  String? _getConversionValidation(String value) {
    if (value.isEmpty) {
      return 'Enter loyalty points to convert';
    }

    final points = int.tryParse(value);
    if (points == null) {
      return 'Enter a valid number';
    }

    if (points <= 0) {
      return 'Points must be greater than 0';
    }

    final totalPoints =
        Get.find<ProfileController>().userProfile?.loyaltyPoints ?? 0;
    if (points > totalPoints) {
      return 'You only have ${NumberFormat.decimalPattern().format(totalPoints)} points';
    }

    return null;
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B2D) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            color: isDark ? Colors.white54 : ColorResource.textLight,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No loyalty activity yet',
            style: poppinsMedium.copyWith(
              color: isDark ? Colors.white : ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Delivered orders will appear here with earned points.',
            textAlign: TextAlign.center,
            style: poppinsRegular.copyWith(
              color: isDark ? Colors.white70 : ColorResource.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
