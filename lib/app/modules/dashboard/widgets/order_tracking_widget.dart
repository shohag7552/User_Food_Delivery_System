import 'package:flutter/material.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';

class OrderTrackingWidget extends StatelessWidget {
  final String orderId;
  final String status;
  final String estimatedTime;
  final String? driverName;
  final String? driverPhone;
  final VoidCallback onTrackOrder;

  const OrderTrackingWidget({
    super.key,
    required this.orderId,
    required this.status,
    required this.estimatedTime,
    this.driverName,
    this.driverPhone,
    required this.onTrackOrder,
  });

  int get currentStep {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 0;
      case 'preparing':
        return 1;
      case 'on the way':
      case 'on_the_way':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryMedium.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Order',
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: ColorResource.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #$orderId',
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textWhite.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ColorResource.textWhite.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(Constants.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: ColorResource.textWhite,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      estimatedTime,
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.textWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Status timeline
          Row(
            children: [
              _buildTimelineStep(
                icon: Icons.check_circle,
                label: 'Confirmed',
                isActive: currentStep >= 0,
                isCompleted: currentStep > 0,
              ),
              _buildTimelineLine(isActive: currentStep >= 1),
              _buildTimelineStep(
                icon: Icons.restaurant,
                label: 'Preparing',
                isActive: currentStep >= 1,
                isCompleted: currentStep > 1,
              ),
              _buildTimelineLine(isActive: currentStep >= 2),
              _buildTimelineStep(
                icon: Icons.delivery_dining,
                label: 'On the way',
                isActive: currentStep >= 2,
                isCompleted: currentStep > 2,
              ),
              _buildTimelineLine(isActive: currentStep >= 3),
              _buildTimelineStep(
                icon: Icons.home,
                label: 'Delivered',
                isActive: currentStep >= 3,
                isCompleted: false,
              ),
            ],
          ),
          // Driver info if available
          if (driverName != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorResource.textWhite.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ColorResource.textWhite,
                    child: Icon(
                      Icons.person,
                      color: ColorResource.primaryDark,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName!,
                          style: poppinsMedium.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: ColorResource.textWhite,
                          ),
                        ),
                        Text(
                          'Delivery Partner',
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: ColorResource.textWhite.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (driverPhone != null)
                    IconButton(
                      onPressed: () {
                        // TODO: Call driver
                      },
                      icon: Icon(
                        Icons.phone,
                        color: ColorResource.textWhite,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Track order button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTrackOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.textWhite,
                foregroundColor: ColorResource.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
                elevation: 0,
              ),
              child: Text(
                'Track Live Order',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? ColorResource.textWhite
                : ColorResource.textWhite.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            size: 16,
            color:
                isActive ? ColorResource.primaryDark : ColorResource.textWhite,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: poppinsRegular.copyWith(
              fontSize: 10,
              color: ColorResource.textWhite.withOpacity(isActive ? 1.0 : 0.5),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 40),
        decoration: BoxDecoration(
          color: isActive
              ? ColorResource.textWhite
              : ColorResource.textWhite.withOpacity(0.3),
        ),
      ),
    );
  }
}
