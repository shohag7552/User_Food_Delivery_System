import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeliveryScheduleBottomSheet extends StatefulWidget {
  final String? initialType; // 'now' or 'schedule'
  final DateTime? initialDate;
  final String? initialTimeSlot;

  const DeliveryScheduleBottomSheet({
    super.key,
    this.initialType,
    this.initialDate,
    this.initialTimeSlot,
  });

  @override
  State<DeliveryScheduleBottomSheet> createState() =>
      _DeliveryScheduleBottomSheetState();

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? initialType,
    DateTime? initialDate,
    String? initialTimeSlot,
  }) async {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeliveryScheduleBottomSheet(
        initialType: initialType,
        initialDate: initialDate,
        initialTimeSlot: initialTimeSlot,
      ),
    );
  }
}

class _DeliveryScheduleBottomSheetState
    extends State<DeliveryScheduleBottomSheet> {
  String _deliveryType = 'now';
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    _deliveryType = widget.initialType ?? 'now';
    _selectedDate = widget.initialDate;
    _selectedTimeSlot = widget.initialTimeSlot;
  }

  void _confirm() {
    if (_deliveryType == 'now') {
      Navigator.pop(context, {
        'type': 'now',
        'date': null,
        'timeSlot': null,
        'displayText': 'asap_mins'.tr,
      });
    } else {
      if (_selectedDate == null || _selectedTimeSlot == null) {
        customToster('please_select_date_time'.tr, isSuccess: false);
        return;
      }

      final dateStr = _selectedDate!.day == DateTime.now().day
          ? 'today'.tr
          : 'tomorrow'.tr;

      Navigator.pop(context, {
        'type': 'schedule',
        'date': _selectedDate,
        'timeSlot': _selectedTimeSlot,
        'displayText': '$dateStr, $_selectedTimeSlot',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final businessSetup = settingsController.businessSetup;
    final isStoreOpen = businessSetup?.isStoreOpen ?? false;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Constants.radiusExtraLarge),
            ),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Now option
                      _buildDeliveryOption(
                        type: 'now',
                        title: 'deliver_now'.tr,
                        subtitle: isStoreOpen
                            ? 'asap_mins'.tr
                            : 'store_closed'.tr,
                        icon: Icons.flash_on_rounded,
                        isAvailable: isStoreOpen,
                      ),
                      const SizedBox(height: 12),

                      // Schedule option
                      _buildDeliveryOption(
                        type: 'schedule',
                        title: 'schedule_delivery'.tr,
                        subtitle: 'pick_specific_time'.tr,
                        icon: Icons.calendar_today_rounded,
                        isAvailable: true,
                      ),

                      // Time slot selection (only for schedule)
                      if (_deliveryType == 'schedule') ...[
                        const SizedBox(height: 24),
                        _buildTimeSlotSelection(businessSetup),
                      ],
                    ],
                  ),
                ),
              ),

              // Confirm button
              _buildConfirmButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Constants.radiusExtraLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorResource.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: ColorResource.primaryGradient,
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: ColorResource.textWhite,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'delivery_schedule'.tr,
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeExtraLarge,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'choose_when_to_deliver'.tr,
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.scaffoldBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: context.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isAvailable,
  }) {
    final isSelected = _deliveryType == type;

    return GestureDetector(
      onTap: !isAvailable
          ? null
          : () {
              setState(() {
                _deliveryType = type;
                if (type == 'now') {
                  _selectedDate = null;
                  _selectedTimeSlot = null;
                }
              });
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: !isAvailable
              ? Colors.grey[100]
              : (isSelected
                  ? ColorResource.primaryDark.withValues(alpha: 0.1)
                  : context.scaffoldBackground),
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          border: Border.all(
            color: !isAvailable
                ? Colors.grey[300]!
                : (isSelected ? ColorResource.primaryDark : Colors.transparent),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: !isAvailable
                    ? Colors.grey[300]
                    : (isSelected
                        ? ColorResource.primaryDark
                        : ColorResource.primaryDark.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              child: Icon(
                icon,
                color: !isAvailable
                    ? Colors.grey
                    : (isSelected ? Colors.white : ColorResource.primaryDark),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: !isAvailable
                          ? Colors.grey
                          : (isSelected
                              ? ColorResource.primaryDark
                              : context.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: !isAvailable
                          ? Colors.grey
                          : context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ColorResource.primaryDark,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelection(dynamic businessSetup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_day'.tr,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildDayOptions(businessSetup),
        if (_selectedDate != null) ...[
          const SizedBox(height: 24),
          Text(
            'select_time_slot'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimeSlots(businessSetup),
        ],
      ],
    );
  }

  Widget _buildDayOptions(dynamic businessSetup) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    return Column(
      children: [
        _buildDayCard(today, 'today'.tr, businessSetup),
        const SizedBox(height: 12),
        _buildDayCard(tomorrow, 'tomorrow'.tr, businessSetup),
      ],
    );
  }

  Widget _buildDayCard(DateTime date, String label, dynamic businessSetup) {
    final isSelected = _selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day;

    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _selectedTimeSlot = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorResource.primaryDark.withValues(alpha: 0.1)
              : context.scaffoldBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          border: Border.all(
            color: isSelected ? ColorResource.primaryDark : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? ColorResource.primaryDark
                    : ColorResource.primaryDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: poppinsBold.copyWith(
                      fontSize: 20,
                      color: isSelected ? Colors.white : ColorResource.primaryDark,
                    ),
                  ),
                  Text(
                    monthNames[date.month - 1],
                    style: poppinsMedium.copyWith(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : ColorResource.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: isSelected
                          ? ColorResource.primaryDark
                          : context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getAvailabilityText(date, businessSetup),
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: context.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ColorResource.primaryDark,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  String _getAvailabilityText(DateTime date, dynamic businessSetup) {
    if (businessSetup == null) return 'check_store_hours'.tr;

    final dayOfWeek = date.weekday % 7;
    final daySchedule = businessSetup.businessHours.getDay(dayOfWeek);

    if (!daySchedule.isOpen || daySchedule.timeSlots.isEmpty) {
      return 'store_closed'.tr;
    }

    final slots = _generateTimeSlots(date, businessSetup);
    if (slots.isEmpty) {
      return 'no_slots_available'.tr;
    }

    return '${slots.length} ${'slots_available'.tr}';
  }

  Widget _buildTimeSlots(dynamic businessSetup) {
    if (businessSetup == null) return const SizedBox.shrink();

    final slots = _generateTimeSlots(_selectedDate!, businessSetup);

    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'no_time_slots_today'.tr,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: Colors.orange[900],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = _selectedTimeSlot == slot;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTimeSlot = slot;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorResource.primaryDark
                  : context.scaffoldBackground,
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
              border: Border.all(
                color: isSelected
                    ? ColorResource.primaryDark
                    : context.textLight.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_circle,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                ],
                Text(
                  slot,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: isSelected ? Colors.white : context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        boxShadow: [
          BoxShadow(
            color: ColorResource.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
            ),
            child: Text(
              'confirm_schedule'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _generateTimeSlots(DateTime date, dynamic businessSetup) {
    final dayOfWeek = date.weekday % 7;
    final daySchedule = businessSetup.businessHours.getDay(dayOfWeek);

    if (!daySchedule.isOpen || daySchedule.timeSlots.isEmpty) {
      return [];
    }

    final List<String> slots = [];
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    for (final timeSlot in daySchedule.timeSlots) {
      final openHour = timeSlot.openTime.hour;
      final closeHour = timeSlot.closeTime.hour;

      for (int hour = openHour; hour < closeHour; hour++) {
        final slotTime = DateTime(date.year, date.month, date.day, hour, 0);

        if (isToday && slotTime.isBefore(now.add(const Duration(hours: 1)))) {
          continue;
        }

        final startTime = _formatTime(hour, 0);
        final endTime = _formatTime(hour + 1, 0);
        slots.add('$startTime - $endTime');
      }
    }

    return slots;
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
