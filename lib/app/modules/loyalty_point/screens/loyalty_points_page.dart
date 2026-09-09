import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/common/widgets/web_footer.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/loyalty_controller.dart';
import 'package:appwrite_user_app/app/controllers/profile_controller.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Get.find<LoyaltyController>().fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWeb = WebTopNav.isEnabled(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isWeb
          ? WebTopNav(
              selectedIndex: null,
              onDestinationSelected: (index) =>
                  DashboardTabs.open(context, index),
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            )
          : AppBar(
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
      endDrawer: isWeb ? const WebProfileDrawer() : null,
      body: AuthGate(
        child: GetBuilder<LoyaltyController>(
          builder: (loyaltyController) {
            return GetBuilder<ProfileController>(
              builder: (profileController) {
                final user = profileController.userProfile;
                final totalPoints = user?.loyaltyPoints ?? 0;

                return RefreshIndicator(
                  onRefresh: loyaltyController.fetchHistory,
                  child: LayoutBuilder(
                    builder: (context, viewport) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: isWeb ? viewport.maxHeight : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: isWeb
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.start,
                          children: [
                            Padding(
                              // Horizontal inset moves inside the band on web, so
                              // the band itself can be the nav's; mobile keeps 16.
                              padding: EdgeInsets.fromLTRB(
                                isWeb ? 0 : 16,
                                16,
                                isWeb ? 0 : 16,
                                24,
                              ),
                              child: Center(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final screenWidth = MediaQuery.of(
                                      context,
                                    ).size.width;
                                    // `isWeb` already requires >= 900, so the old
                                    // `isWeb && width >= 900` was always equal to
                                    // it — and its 720px branch was unreachable.
                                    final isWideWeb = isWeb;

                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        // The content band, shared with the top
                                        // nav. At 1000 the card sat 100px inside
                                        // the bar above it on every side.
                                        maxWidth: isWeb
                                            ? WebTopNav.maxContentWidth
                                            : double.infinity,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isWeb
                                              ? WebTopNav.bandInsetFor(
                                                  screenWidth,
                                                )
                                              : 0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (isWeb) ...[
                                              Text(
                                                'Loyalty Points',
                                                style: poppinsBold.copyWith(
                                                  fontSize: Constants
                                                      .fontSizeOverLarge,
                                                  color: isDark
                                                      ? Colors.white
                                                      : context.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                            ],
                                            if (isWideWeb)
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Left side: Summary Card
                                                  Expanded(
                                                    flex: 42,
                                                    child: _buildSummaryCard(
                                                      context: context,
                                                      userName: user?.name,
                                                      totalPoints: totalPoints,
                                                      walletConversionRate:
                                                          loyaltyController
                                                              .walletConversionRate,
                                                      isConverting:
                                                          loyaltyController
                                                              .isConverting,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 32),
                                                  // Right side: Activity List
                                                  Expanded(
                                                    flex: 58,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Points activity',
                                                          style: poppinsBold.copyWith(
                                                            fontSize: Constants
                                                                .fontSizeLarge,
                                                            color: isDark
                                                                ? Colors.white
                                                                : context
                                                                      .textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          'Track how points are earned and redeemed across your account.',
                                                          style: poppinsRegular
                                                              .copyWith(
                                                                color: isDark
                                                                    ? Colors
                                                                          .white70
                                                                    : context
                                                                          .textSecondary,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        if (loyaltyController
                                                            .isLoading)
                                                          const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          )
                                                        else if (loyaltyController
                                                            .history
                                                            .isEmpty)
                                                          _buildEmptyState(
                                                            context,
                                                          )
                                                        else
                                                          ...loyaltyController.history.map(
                                                            (
                                                              transaction,
                                                            ) => Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    bottom: 12,
                                                                  ),
                                                              child:
                                                                  _buildTransactionCard(
                                                                    context,
                                                                    transaction,
                                                                  ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else ...[
                                              _buildSummaryCard(
                                                context: context,
                                                userName: user?.name,
                                                totalPoints: totalPoints,
                                                walletConversionRate:
                                                    loyaltyController
                                                        .walletConversionRate,
                                                isConverting: loyaltyController
                                                    .isConverting,
                                              ),
                                              const SizedBox(height: 24),
                                              Text(
                                                'Points activity',
                                                style: poppinsBold.copyWith(
                                                  fontSize:
                                                      Constants.fontSizeLarge,
                                                  color: isDark
                                                      ? Colors.white
                                                      : context.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Track how points are earned and redeemed across your account.',
                                                style: poppinsRegular.copyWith(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : context.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              if (loyaltyController.isLoading)
                                                const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                              else if (loyaltyController
                                                  .history
                                                  .isEmpty)
                                                _buildEmptyState(context)
                                              else
                                                ...loyaltyController.history.map(
                                                  (transaction) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 12,
                                                        ),
                                                    child:
                                                        _buildTransactionCard(
                                                          context,
                                                          transaction,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Full-width footer pinned to the bottom on web.
                            if (isWeb) const WebFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Stepped off the brand rather than hard-coded, so this panel follows
          // `Constants.primaryColor` with the rest of the app. The factors were
          // fitted to the reds that were here before, so the gradient is
          // unchanged for the shipped brand.
          colors: isDark
              ? [
                  ColorResource.brandShade(0.29),
                  ColorResource.brandShade(0.47),
                  ColorResource.brandShade(0.63),
                ]
              : [
                  ColorResource.primaryMedium,
                  ColorResource.primaryDark,
                  ColorResource.brandShade(0.21),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(
            0xFFFFD700,
          ).withValues(alpha: isDark ? 0.25 : 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryDark.withValues(
              alpha: isDark ? 0.35 : 0.2,
            ),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background watermark badge icon
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 200,
              color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Premium Chip and Logo
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFDF7A), Color(0xFFD4AF37)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.nfc_rounded,
                            color: Color(0xFF5A4500),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'VIP CLUB',
                          style: poppinsBold.copyWith(
                            color: const Color(0xFFFFD700),
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    // Conversion Rate Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFFD700,
                        ).withValues(alpha: isDark ? 0.12 : 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(
                            0xFFFFD700,
                          ).withValues(alpha: isDark ? 0.3 : 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$walletConversionRate pts = ${CurrencyHelper.formatAmount(1)}',
                        style: poppinsBold.copyWith(
                          color: const Color(0xFFFFD700),
                          fontSize: Constants.fontSizeSmall - 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  userName?.isNotEmpty == true
                      ? userName!.toUpperCase()
                      : 'LOYALTY MEMBER',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: poppinsBold.copyWith(
                    color: Colors.white.withValues(alpha: isDark ? 0.6 : 0.7),
                    fontSize: Constants.fontSizeSmall,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      NumberFormat.decimalPattern().format(totalPoints),
                      style: poppinsBold.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                        height: 1,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PTS',
                      style: poppinsBold.copyWith(
                        color: const Color(0xFFFFD700),
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Convert your reward points to wallet credit instantly.',
                  style: poppinsRegular.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: Constants.fontSizeDefault,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient:
                        totalPoints == 0 ||
                            walletConversionRate <= 0 ||
                            isConverting
                        ? null
                        : LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFFFFE082),
                                    const Color(0xFFFFB300),
                                  ]
                                : [
                                    const Color(0xFFFFEEB3),
                                    const Color(0xFFFFC107),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color:
                        totalPoints == 0 ||
                            walletConversionRate <= 0 ||
                            isConverting
                        ? Colors.white.withValues(alpha: 0.12)
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow:
                        totalPoints == 0 ||
                            walletConversionRate <= 0 ||
                            isConverting
                        ? null
                        : [
                            BoxShadow(
                              color:
                                  (isDark
                                          ? const Color(0xFFFFB300)
                                          : const Color(0xFFFFC107))
                                      .withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap:
                          totalPoints == 0 ||
                              walletConversionRate <= 0 ||
                              isConverting
                          ? null
                          : _handleConvertToWallet,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: isConverting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Convert to Wallet',
                                style: poppinsBold.copyWith(
                                  fontSize: 16,
                                  color:
                                      totalPoints == 0 ||
                                          walletConversionRate <= 0 ||
                                          isConverting
                                      ? Colors.white.withValues(alpha: 0.35)
                                      : const Color(0xFF5A4500),
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                    color: isDark ? Colors.white : context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: poppinsRegular.copyWith(
                    color: isDark ? Colors.white70 : context.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat(
                    'dd MMM yyyy, hh:mm a',
                  ).format(transaction.createdAt),
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: isDark ? Colors.white54 : context.textLight,
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
                  color: isDark ? Colors.white54 : context.textLight,
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
              totalPoints: totalPoints,
              walletConversionRate: walletConversionRate,
            );
            final convertedAmount = CurrencyHelper.formatWithSeparators(
              enteredPoints / walletConversionRate,
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
                      style: poppinsMedium.copyWith(color: context.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Conversion rate: $walletConversionRate points = ${CurrencyHelper.formatAmount(1)}',
                      style: poppinsRegular.copyWith(
                        color: context.textSecondary,
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
                              color: context.textSecondary,
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
                    style: poppinsMedium.copyWith(color: context.textSecondary),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: GetBuilder<LoyaltyController>(
                    builder: (controller) {
                      return CustomButton(
                        onPressed:
                            validationMessage != null || controller.isConverting
                            ? null
                            : () async {
                                final converted = await controller
                                    .convertPointsToWallet(enteredPoints);
                                if (converted && dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                              },
                        buttonText: 'Convert',
                        height: 46,
                        elevation: 0,
                        isLoading: controller.isConverting,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => pointsController.dispose());
  }

  String? _getConversionValidation(
    String value, {
    required int totalPoints,
    required double walletConversionRate,
  }) {
    if (value.isEmpty) {
      return 'Enter loyalty points to convert';
    }

    if (walletConversionRate <= 0) {
      return 'Wallet conversion is unavailable';
    }

    final points = int.tryParse(value);
    if (points == null) {
      return 'Enter a valid number';
    }

    if (points <= 0) {
      return 'Points must be greater than 0';
    }

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
            color: isDark ? Colors.white54 : context.textLight,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No loyalty activity yet',
            style: poppinsMedium.copyWith(
              color: isDark ? Colors.white : context.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Delivered orders will appear here with earned points.',
            textAlign: TextAlign.center,
            style: poppinsRegular.copyWith(
              color: isDark ? Colors.white70 : context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
