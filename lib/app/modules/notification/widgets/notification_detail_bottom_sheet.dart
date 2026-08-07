import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/notification_model.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';



class NotificationDetailBottomSheet extends StatefulWidget {
  final NotificationModel notification;
  final bool isDialog;

  const NotificationDetailBottomSheet({
    super.key,
    required this.notification,
    this.isDialog = false,
  });

  static void show(BuildContext context, NotificationModel notification) {
    final isWeb = WebTopNav.isEnabled(context);
    if (isWeb) {
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: NotificationDetailBottomSheet(notification: notification, isDialog: true),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        builder: (_) => NotificationDetailBottomSheet(notification: notification),
      );
    }
  }

  @override
  State<NotificationDetailBottomSheet> createState() =>
      _NotificationDetailBottomSheetState();
}

class _NotificationDetailBottomSheetState
    extends State<NotificationDetailBottomSheet> {
  bool _isLoadingActionData = false;
  OrderModel? _fetchedOrder;
  ProductModel? _fetchedProduct;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _fetchActionData();
  }

  Future<void> _fetchActionData() async {
    final actionType = widget.notification.actionType;
    final actionValue = widget.notification.actionValue;

    if (actionValue == null || actionValue.isEmpty) return;

    if (actionType == 'order') {
      setState(() {
        _isLoadingActionData = true;
        _fetchError = null;
      });
      try {
        final order =
            await Get.find<OrderController>().fetchOrderDetails(actionValue, showLoader: false);
        if (mounted) {
          setState(() {
            _fetchedOrder = order;
            _isLoadingActionData = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _fetchError = 'failed_to_load_order_details'.trClean;
            _isLoadingActionData = false;
          });
        }
      }
    } else if (actionType == 'product') {
      setState(() {
        _isLoadingActionData = true;
        _fetchError = null;
      });
      try {
        final product =
            await Get.find<ProductController>().getProductById(actionValue);
        if (mounted) {
          setState(() {
            _fetchedProduct = product;
            _isLoadingActionData = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _fetchError = 'failed_to_load_product_details'.trClean;
            _isLoadingActionData = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final content = Container(
      width: widget.isDialog ? 550 : double.infinity,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: widget.isDialog
            ? BorderRadius.circular(28)
            : const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isDialog) _buildDragHandle(),
          _buildHeader(context),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildIconBanner(),
                  _buildBody(),
                  if (_isLoadingActionData)
                    _buildActionLoader()
                  else if (_fetchError != null)
                    _buildActionError()
                  else if (_fetchedOrder != null)
                    _buildOrderPreview()
                  else if (_fetchedProduct != null)
                    _buildProductPreview(),
                  _buildMetaInfo(),
                  _buildActionButton(context),
                  SizedBox(
                    height: widget.isDialog
                        ? 24
                        : (MediaQuery.of(context).padding.bottom + 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return widget.isDialog ? Center(child: content) : content;
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: ColorResource.textLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'notification_detail'.trClean,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: context.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.scaffoldBackground,
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBanner() {
    final config = _getTypeConfig();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.color.withValues(alpha: 0.12),
            config.color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
        border: Border.all(
          color: config.color.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  config.color.withValues(alpha: 0.9),
                  config.color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: config.color.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(config.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypeBadge(label: config.label, color: config.color),
                const SizedBox(height: 6),
                Text(
                  widget.notification.title,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: context.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'message'.trClean),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.scaffoldBackground,
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              border: Border.all(
                color: ColorResource.textLight.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              widget.notification.message,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textPrimary,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionLoader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: ColorResource.primaryDark,
          ),
        ),
      ),
    );
  }

  Widget _buildActionError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ColorResource.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
          border: Border.all(
            color: ColorResource.error.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: ColorResource.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _fetchError ?? '',
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderPreview() {
    final order = _fetchedOrder!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'associated_order'.trClean),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.scaffoldBackground,
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              border: Border.all(
                color: ColorResource.primaryMedium.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${'order_id'.trClean}: #${order.id.substring(0, min(8, order.id.length))}',
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: context.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorResource.primaryMedium.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(Constants.radiusSmall),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeExtraSmall,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.items.length} ${order.items.length == 1 ? 'item'.trClean : 'items'.trClean}',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: context.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPreview() {
    final product = _fetchedProduct!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'associated_product'.trClean),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.scaffoldBackground,
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              border: Border.all(
                color: ColorResource.primaryMedium.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                  child: CustomNetworkImage(
                    image: product.imageId,
                    width: 64,
                    height: 64,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nameMap.trLanguage,
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product.finalPrice.toStringAsFixed(2)}',
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo() {
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a')
        .format(widget.notification.createdAt.toLocal());
    final config = _getTypeConfig();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'details'.trClean),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: context.scaffoldBackground,
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              border: Border.all(
                color: ColorResource.textLight.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                _MetaRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'received'.trClean,
                  value: formattedDate,
                  iconColor: ColorResource.primaryMedium,
                ),
                _Divider(),
                _MetaRow(
                  icon: Icons.access_time_outlined,
                  label: 'time_ago'.trClean,
                  value: timeago.format(widget.notification.createdAt),
                  iconColor: ColorResource.primaryMedium,
                ),
                _Divider(),
                _MetaRow(
                  icon: config.icon,
                  label: 'category'.trClean,
                  value: config.label,
                  iconColor: config.color,
                ),
                _Divider(),
                _MetaRow(
                  icon: widget.notification.isRead
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                  label: 'status'.trClean,
                  value: widget.notification.isRead ? 'read'.trClean : 'unread'.trClean,
                  iconColor: widget.notification.isRead
                      ? ColorResource.success
                      : ColorResource.warning,
                  valueColor: widget.notification.isRead
                      ? ColorResource.success
                      : ColorResource.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final actionType = widget.notification.actionType;
    final actionValue = widget.notification.actionValue;
    final hasAction = actionType != null &&
        actionType != 'none' &&
        actionValue != null &&
        actionValue.isNotEmpty;

    if (!hasAction) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              'got_it'.trClean,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textWhite,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.primaryDark,
              foregroundColor: ColorResource.textWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
            ),
          ),
        ),
      );
    }

    final config = _getTypeConfig();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _handleActionClick(context),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text(
                  _getActionLabel(),
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: ColorResource.textWhite,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.color,
                  foregroundColor: ColorResource.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Constants.radiusLarge),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.textLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusLarge),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                'dismiss'.trClean,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: context.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleActionClick(BuildContext context) async {
    final actionType = widget.notification.actionType;
    final actionValue = widget.notification.actionValue;

    Navigator.of(context).pop();

    if (actionType == 'order' && actionValue != null) {
      context.pushNamed(
        RouteNames.orderDetail,
        pathParameters: {'id': actionValue},
        extra: _fetchedOrder,
      );
    } else if (actionType == 'product' && actionValue != null) {
      if (_fetchedProduct != null) {
        context.pushNamed(
          RouteNames.productDetail,
          pathParameters: {'id': actionValue},
          extra: _fetchedProduct,
        );
      } else {
        try {
          final product =
              await Get.find<ProductController>().getProductById(actionValue);
          if (product != null && context.mounted) {
            context.pushNamed(
              RouteNames.productDetail,
              pathParameters: {'id': actionValue},
              extra: product,
            );
          }
        } catch (_) {}
      }
    } else if (actionType == 'url' && actionValue != null) {
      final uri = Uri.tryParse(actionValue);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _getActionLabel() {
    switch (widget.notification.actionType) {
      case 'order':
        return 'view_order'.trClean;
      case 'product':
        return 'view_product'.trClean;
      case 'url':
        return 'open_link'.trClean;
      default:
        return 'view_details'.trClean;
    }
  }

  _NotificationTypeConfig _getTypeConfig() {
    switch (widget.notification.type) {
      case 'order':
        return _NotificationTypeConfig(
          icon: Icons.shopping_bag_rounded,
          color: const Color(0xFF10B981),
          label: 'order'.trClean,
        );
      case 'promo':
        return _NotificationTypeConfig(
          icon: Icons.local_offer_rounded,
          color: const Color(0xFFF59E0B),
          label: 'promo'.trClean,
        );
      case 'system':
        return _NotificationTypeConfig(
          icon: Icons.info_rounded,
          color: const Color(0xFF3B82F6),
          label: 'system'.trClean,
        );
      default:
        return _NotificationTypeConfig(
          icon: Icons.notifications_rounded,
          color: ColorResource.primaryMedium,
          label: 'general'.trClean,
        );
    }
  }

  int min(int a, int b) => a < b ? a : b;
}

// ─── Helper Models ───────────────────────────────────────────────────────────

class _NotificationTypeConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _NotificationTypeConfig({
    required this.icon,
    required this.color,
    required this.label,
  });
}

// ─── Reusable Sub-widgets ────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: poppinsMedium.copyWith(
          fontSize: 10,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: poppinsMedium.copyWith(
        fontSize: Constants.fontSizeSmall,
        color: context.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color? valueColor;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: context.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: valueColor ?? context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: context.textLight.withValues(alpha: 0.2),
    );
  }
}
