import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/controllers/profile_controller.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LoyaltyPointsPage extends StatefulWidget {
  const LoyaltyPointsPage({super.key});

  @override
  State<LoyaltyPointsPage> createState() => _LoyaltyPointsPageState();
}

class _LoyaltyPointsPageState extends State<LoyaltyPointsPage> {
  static const double _walletConversionRate = 0.10;

  final List<_LoyaltyTransaction> _transactions = const [
    _LoyaltyTransaction(
      title: 'Order reward',
      subtitle: 'Earned from order #12847',
      points: 180,
      type: _LoyaltyTransactionType.earned,
      date: '2026-04-20T18:40:00',
    ),
    _LoyaltyTransaction(
      title: 'Weekend campaign bonus',
      subtitle: 'Limited-time promotional reward',
      points: 120,
      type: _LoyaltyTransactionType.earned,
      date: '2026-04-18T12:00:00',
    ),
    _LoyaltyTransaction(
      title: 'Wallet conversion',
      subtitle: 'Converted to wallet balance',
      points: 150,
      type: _LoyaltyTransactionType.redeemed,
      date: '2026-04-15T10:15:00',
    ),
    _LoyaltyTransaction(
      title: 'First order bonus',
      subtitle: 'Welcome reward for your first purchase',
      points: 250,
      type: _LoyaltyTransactionType.earned,
      date: '2026-04-09T16:30:00',
    ),
  ];

  int get _totalPoints {
    return _transactions.fold<int>(0, (sum, item) {
      return sum +
          (item.type == _LoyaltyTransactionType.earned
              ? item.points
              : -item.points);
    });
  }

  double get _walletValue => _totalPoints * _walletConversionRate;

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
      body: GetBuilder<ProfileController>(
        builder: (controller) {
          final user = controller.userProfile;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(
                  context: context,
                  userName: user?.name,
                ),
                const SizedBox(height: 24),
                Text(
                  'Points activity',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: isDark ? Colors.white : ColorResource.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track how points are earned and redeemed across your account.',
                  style: poppinsRegular.copyWith(
                    color: isDark ? Colors.white70 : ColorResource.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ..._transactions.map(
                  (transaction) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTransactionCard(context, transaction),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String? userName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE25757),
            Color(0xFFC92A2A),
            Color(0xFF7F1D1D),
          ],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '1 point = ${CurrencyHelper.formatAmount(_walletConversionRate)}',
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
            NumberFormat.decimalPattern().format(_totalPoints),
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
            onPressed: _totalPoints == 0 ? null : _handleConvertToWallet,
            buttonText: 'Convert to Wallet',
            height: 52,
            elevation: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    _LoyaltyTransaction transaction,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEarned = transaction.type == _LoyaltyTransactionType.earned;
    final accentColor =
        isEarned ? ColorResource.success : ColorResource.warning;

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
                  transaction.subtitle,
                  style: poppinsRegular.copyWith(
                    color: isDark ? Colors.white70 : ColorResource.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a')
                      .format(transaction.parsedDate),
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
    final convertedAmount = CurrencyHelper.formatWithSeparators(_walletValue);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Convert loyalty points',
            style: poppinsBold.copyWith(fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You can convert ${NumberFormat.decimalPattern().format(_totalPoints)} loyalty points into $convertedAmount wallet balance.',
                style: poppinsRegular.copyWith(
                  color: ColorResource.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorResource.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total points',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.decimalPattern().format(_totalPoints),
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeLarge,
                        color: ColorResource.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Wallet amount',
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Close',
                style: poppinsMedium.copyWith(
                  color: ColorResource.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _LoyaltyTransactionType { earned, redeemed }

class _LoyaltyTransaction {
  final String title;
  final String subtitle;
  final int points;
  final _LoyaltyTransactionType type;
  final String date;

  const _LoyaltyTransaction({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.type,
    required this.date,
  });

  DateTime get parsedDate => DateTime.parse(date);
}
