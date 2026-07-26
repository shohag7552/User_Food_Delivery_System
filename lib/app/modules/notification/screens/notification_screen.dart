import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/web_footer.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/notification_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/models/notification_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/modules/notification/widgets/notification_detail_bottom_sheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Caps the list width on desktop web so cards stay readable.
  static const double _maxContentWidth = 720;

  @override
  void initState() {
    super.initState();

    Get.find<NotificationController>().getNotifications();
  }

  double _sidePadding(double width, bool isWeb) =>
      isWeb && width > _maxContentWidth ? (width - _maxContentWidth) / 2 : 16;

  @override
  Widget build(BuildContext context) {
    final isWeb = WebTopNav.isEnabled(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.scaffoldBackground,
      // On web the shared top-nav has no custom actions, so "mark all read"
      // moves into the inline header below.
      appBar: isWeb
          ? WebTopNav(
              selectedIndex: null,
              onDestinationSelected: (index) =>
                  DashboardTabs.open(context, index),
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            )
          : CustomAppbar(
              title: 'notifications_title'.tr,
              actions: [
                GetBuilder<NotificationController>(
                  builder: (controller) {
                    if (!controller.isLoading &&
                        controller.notifications.isNotEmpty) {
                      return TextButton(
                        onPressed: () => controller.markAllAsRead(),
                        child: Text(
                          'mark_all_read'.tr,
                          style: poppinsMedium.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: ColorResource.textWhite,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
      endDrawer: isWeb ? const WebProfileDrawer() : null,
      body: AuthGate(
        child: GetBuilder<NotificationController>(
        builder: (controller) {
          if (controller.isLoading) {
            return _buildLoadingState(context, isWeb);
          }

          if (controller.notifications.isEmpty) {
            return _buildEmptyState();
          }

          final width = MediaQuery.of(context).size.width;
          final sidePadding = _sidePadding(width, isWeb);

          if (!isWeb) {
            return RefreshIndicator(
              onRefresh: () => controller.getNotifications(),
              color: ColorResource.primaryDark,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(sidePadding, 16, sidePadding, 24),
                itemCount: controller.notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildNotificationCard(
                    controller.notifications[index], controller),
              ),
            );
          }

          // Web: inline header (title + "mark all read") over the full-width
          // list, with the footer pinned to the bottom of the viewport.
          return Column(
            children: [
              _buildWebHeader(controller, sidePadding),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.getNotifications(),
                  color: ColorResource.primaryDark,
                  child: LayoutBuilder(
                    builder: (context, viewport) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        // At least a full viewport tall so the footer anchors to
                        // the bottom when the list is short.
                        constraints:
                            BoxConstraints(minHeight: viewport.maxHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  sidePadding, 8, sidePadding, 24),
                              child: Column(
                                children: [
                                  for (int i = 0;
                                      i < controller.notifications.length;
                                      i++)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: i ==
                                                controller.notifications.length -
                                                    1
                                            ? 0
                                            : 12,
                                      ),
                                      child: _buildNotificationCard(
                                          controller.notifications[i],
                                          controller),
                                    ),
                                ],
                              ),
                            ),
                            const WebFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  Widget _buildWebHeader(NotificationController controller, double sidePadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(sidePadding, 20, sidePadding, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'notifications_title'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeOverLarge,
                color: context.textPrimary,
              ),
            ),
          ),
          if (controller.notifications.isNotEmpty)
            TextButton.icon(
              onPressed: () => controller.markAllAsRead(),
              icon: Icon(
                Icons.done_all_rounded,
                size: 18,
                color: ColorResource.primaryDark,
              ),
              label: Text(
                'mark_all_read'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.primaryDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, NotificationController controller) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsetsDirectional.only(end: 20),
        decoration: BoxDecoration(
          color: ColorResource.error,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
        ),
        child: Icon(
          Icons.delete_outline,
          color: ColorResource.textWhite,
          size: 28,
        ),
      ),
      onDismissed: (direction) {
        controller.deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () {
          // Show detail bottom sheet immediately (sync, no async gap).
          // Mark as read in the background so there's no BuildContext gap.
          if (!notification.isRead) {
            controller.markAsRead(notification.id);
          }
          NotificationDetailBottomSheet.show(context, notification);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? context.cardBackground
                : context.cardBackground,
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            boxShadow: ColorResource.customShadow,
            border: notification.isRead
                ? null
                : Border.all(
                    color: ColorResource.primaryMedium.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon based on type
              _buildNotificationIcon(notification.type),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: (notification.isRead ? poppinsMedium : poppinsBold).copyWith(
                              fontSize: Constants.fontSizeDefault,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        // Unread indicator
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: ColorResource.primaryDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeago.format(notification.createdAt),
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall - 1,
                        color: context.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'order':
        icon = Icons.shopping_bag_outlined;
        color = Colors.green;
        break;
      case 'promo':
        icon = Icons.local_offer_outlined;
        color = Colors.orange;
        break;
      case 'system':
        icon = Icons.info_outline;
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = ColorResource.primaryDark;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isWeb) {
    final width = MediaQuery.of(context).size.width;
    final sidePadding = _sidePadding(width, isWeb);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(sidePadding, 16, sidePadding, 24),
      itemCount: 8,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.textLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.textLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 200,
                  decoration: BoxDecoration(
                    color: context.textLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: context.textLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: ColorResource.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 60,
                color: ColorResource.textWhite,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'notifications_empty'.tr,
              style: poppinsBold.copyWith(
                fontSize: 24,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'youre_all_caught_up'.tr,
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }


}
