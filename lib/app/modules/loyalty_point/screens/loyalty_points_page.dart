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

  int get _earnedPoints {
    return _transactions
        .where((item) => item.type == _LoyaltyTransactionType.earned)
        .fold<int>(0, (sum, item) => sum + item.points);
  }

  int get _redeemedPoints {
    return _transactions
        .where((item) => item.type == _LoyaltyTransactionType.redeemed)
        .fold<int>(0, (sum, item) => sum + item.points);
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
                  walletBalance: user?.walletBalance ?? 0,
                ),
                const SizedBox(height: 18),
                _buildQuickStats(context),
                const SizedBox(height: 18),
                _buildConversionSection(context, isDark),
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
    required double walletBalance,
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
            'Available points',
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
            'Estimated wallet value: ${CurrencyHelper.formatWithSeparators(_walletValue)}',
            style: poppinsRegular.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: Constants.fontSizeDefault,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: 'Member',
                    value:
                        userName?.isNotEmpty == true ? userName! : 'Guest user',
                    valueColor: Colors.white,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                Expanded(
                  child: _SummaryMetric(
                    label: 'Wallet balance',
                    value:
                        CurrencyHelper.formatWithSeparators(walletBalance),
                    valueColor: Colors.white,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.arrow_downward_rounded,
            label: 'Earned',
            value: NumberFormat.decimalPattern().format(_earnedPoints),
            iconColor: ColorResource.success,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.swap_horiz_rounded,
            label: 'Converted',
            value: NumberFormat.decimalPattern().format(_redeemedPoints),
            iconColor: ColorResource.warning,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildConversionSection(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B2D) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : ColorResource.primaryDark.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorResource.primaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: ColorResource.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Convert points to wallet',
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeLarge,
                        color:
                            isDark ? Colors.white : ColorResource.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use your rewards as wallet credit during checkout.',
                      style: poppinsRegular.copyWith(
                        color: isDark
                            ? Colors.white70
                            : ColorResource.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8F8FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniInfo(
                    title: 'Minimum conversion',
                    value: '100 points',
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _MiniInfo(
                    title: 'Current value',
                    value: CurrencyHelper.formatWithSeparators(_walletValue),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            onPressed: _totalPoints < 100 ? null : _handleConvertToWallet,
            buttonText: _totalPoints < 100
                ? 'Earn 100 points to unlock conversion'
                : 'Convert to Wallet',
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

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Convert loyalty points',
                style: poppinsBold.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'You currently have $_totalPoints points available. This is equal to $convertedAmount in wallet credit.',
                style: poppinsRegular.copyWith(
                  color: ColorResource.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorResource.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Backend conversion is not connected yet. This screen is ready for the real conversion API when you want to hook it up.',
                  style: poppinsMedium.copyWith(
                    color: ColorResource.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              CustomButton(
                onPressed: () {
                  Get.back();
                  Get.snackbar(
                    'Conversion pending',
                    'Connect the wallet conversion API to complete this action.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: ColorResource.primaryDark,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                  );
                },
                buttonText: 'Continue',
                height: 50,
                elevation: 0,
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: poppinsRegular.copyWith(
            color: Colors.white.withValues(alpha: 0.74),
            fontSize: Constants.fontSizeSmall,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: poppinsBold.copyWith(
            color: valueColor,
            fontSize: Constants.fontSizeDefault,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B2D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: poppinsRegular.copyWith(
                    color: isDark ? Colors.white70 : ColorResource.textSecondary,
                    fontSize: Constants.fontSizeSmall,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: isDark ? Colors.white : ColorResource.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String title;
  final String value;
  final bool isDark;

  const _MiniInfo({
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeSmall,
            color: isDark ? Colors.white60 : ColorResource.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: isDark ? Colors.white : ColorResource.textPrimary,
          ),
        ),
      ],
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
