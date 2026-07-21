import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/helper/store_time_helper.dart';
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

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _deliveryType = widget.initialType ?? 'now';
    _selectedDate = widget.initialDate;
    _selectedTimeSlot = widget.initialTimeSlot;
  }

  // ─────────────────────────── Logic (unchanged) ───────────────────────────

  void _confirm() {
    if (_deliveryType == 'now') {
      final businessSetup = Get.find<SettingsController>().businessSetup;
      Navigator.pop(context, {
        'type': 'now',
        'date': null,
        'timeSlot': null,
        'displayText': businessSetup?.asapEstimateLabel ?? 'asap_mins'.tr,
      });
    } else {
      if (_selectedDate == null || _selectedTimeSlot == null) {
        customToster('please_select_date_time'.tr, isSuccess: false);
        return;
      }

      // Compare against the store's calendar day, not the device's, so the
      // Today/Tomorrow label matches the slots the customer actually picked.
      final storeNow = StoreTime.nowCivil();
      final isToday = _selectedDate!.year == storeNow.year &&
          _selectedDate!.month == storeNow.month &&
          _selectedDate!.day == storeNow.day;
      final dateStr = isToday ? 'today'.tr : 'tomorrow'.tr;

      Navigator.pop(context, {
        'type': 'schedule',
        'date': _selectedDate,
        'timeSlot': _selectedTimeSlot,
        'displayText': '$dateStr, $_selectedTimeSlot',
      });
    }
  }

  List<String> _generateTimeSlots(DateTime date, dynamic businessSetup) {
    final dayOfWeek = date.weekday % 7;
    final daySchedule = businessSetup.businessHours.getDay(dayOfWeek);

    if (!daySchedule.isOpen || daySchedule.timeSlots.isEmpty) {
      return [];
    }

    final List<String> slots = [];
    // Evaluate "now" and the 1-hour lead time in the store's timezone so slots
    // are filtered consistently regardless of the customer's device timezone.
    final now = StoreTime.nowCivil();
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

  ({bool isOpen, int slotCount}) _dayAvailability(
      DateTime date, dynamic businessSetup) {
    if (businessSetup == null) return (isOpen: false, slotCount: 0);
    final dayOfWeek = date.weekday % 7;
    final daySchedule = businessSetup.businessHours.getDay(dayOfWeek);
    if (!daySchedule.isOpen || daySchedule.timeSlots.isEmpty) {
      return (isOpen: false, slotCount: 0);
    }
    return (
      isOpen: true,
      slotCount: _generateTimeSlots(date, businessSetup).length,
    );
  }

  // ─────────────────────────────── UI ───────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final businessSetup = settingsController.businessSetup;
    final isStoreOpen = businessSetup?.isStoreOpen ?? false;
    final asapText =
        businessSetup?.asapEstimateLabel ?? 'asap_mins'.tr;
    final isSchedule = _deliveryType == 'schedule';

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.scaffoldBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(
                        'delivery_schedule'.tr,
                        Icons.local_shipping_outlined,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildOptionCard(
                              type: 'now',
                              title: 'deliver_now'.tr,
                              subtitle:
                                  isStoreOpen ? asapText : 'store_closed'.tr,
                              icon: Icons.bolt_rounded,
                              isAvailable: isStoreOpen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildOptionCard(
                              type: 'schedule',
                              title: 'schedule_delivery'.tr,
                              subtitle: 'pick_specific_time'.tr,
                              icon: Icons.event_available_rounded,
                              isAvailable: true,
                            ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: isSchedule
                            ? _buildScheduleSection(businessSetup)
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 14, 16),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: context.textLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: ColorResource.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: ColorResource.primaryDark.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
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
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
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
              _CircleIconButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 17, color: ColorResource.primaryDark),
        const SizedBox(width: 8),
        Text(
          text,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? ColorResource.primaryGradient : null,
          color: isSelected
              ? null
              : (isAvailable
                  ? context.cardBackground
                  : context.textLight.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : context.textLight.withValues(alpha: 0.14),
            width: 1.4,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorResource.primaryDark.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : (isAvailable
                            ? ColorResource.primaryDark.withValues(alpha: 0.1)
                            : context.textLight.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? Colors.white
                        : (isAvailable
                            ? ColorResource.primaryDark
                            : context.textLight),
                  ),
                ),
                AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isSelected ? 1 : 0,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: isSelected
                    ? Colors.white
                    : (isAvailable ? context.textPrimary : context.textLight),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeExtraSmall,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(dynamic businessSetup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildSectionLabel('select_day'.tr, Icons.calendar_today_rounded),
        const SizedBox(height: 14),
        _buildDayOptions(businessSetup),
        if (_selectedDate != null) ...[
          const SizedBox(height: 24),
          _buildSectionLabel(
              'select_time_slot'.tr, Icons.access_time_rounded),
          const SizedBox(height: 14),
          _buildTimeSlots(businessSetup),
        ],
      ],
    );
  }

  Widget _buildDayOptions(dynamic businessSetup) {
    // Days are the STORE's calendar days (its timezone), so the chosen date's
    // Y/M/D matches how the order is later resolved to a UTC slot range.
    final storeNow = StoreTime.nowCivil();
    final today = DateTime(storeNow.year, storeNow.month, storeNow.day);
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

    final availability = _dayAvailability(date, businessSetup);
    const weekdayKeys = [
      'sunday', 'monday', 'tuesday', 'wednesday',
      'thursday', 'friday', 'saturday'
    ];

    Color statusColor;
    String statusText;
    if (!availability.isOpen) {
      statusColor = ColorResource.error;
      statusText = 'store_closed'.tr;
    } else if (availability.slotCount == 0) {
      statusColor = ColorResource.warning;
      statusText = 'no_slots_available'.tr;
    } else {
      statusColor = ColorResource.success;
      statusText = '${availability.slotCount} ${'slots_available'.tr}';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _selectedTimeSlot = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorResource.primaryDark.withValues(alpha: 0.06)
              : context.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? ColorResource.primaryDark
                : context.textLight.withValues(alpha: 0.14),
            width: isSelected ? 1.8 : 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: isSelected ? ColorResource.primaryGradient : null,
                color: isSelected
                    ? null
                    : ColorResource.primaryDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: poppinsBold.copyWith(
                      fontSize: 22,
                      height: 1,
                      color:
                          isSelected ? Colors.white : ColorResource.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _monthNames[date.month - 1],
                    style: poppinsMedium.copyWith(
                      fontSize: 11,
                      height: 1,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : ColorResource.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: context.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    weekdayKeys[date.weekday % 7].tr,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: poppinsMedium.copyWith(
                            fontSize: Constants.fontSizeExtraSmall,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: isSelected ? ColorResource.primaryGradient : null,
                color: isSelected ? null : Colors.transparent,
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(
                        color: context.textLight.withValues(alpha: 0.4),
                        width: 1.6,
                      ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 17)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots(dynamic businessSetup) {
    if (businessSetup == null) return const SizedBox.shrink();

    final slots = _generateTimeSlots(_selectedDate!, businessSetup);

    if (slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorResource.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorResource.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: ColorResource.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'no_time_slots_today'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: context.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: slots.map((slot) {
        final isSelected = _selectedTimeSlot == slot;
        return GestureDetector(
          onTap: () => setState(() => _selectedTimeSlot = slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: isSelected ? ColorResource.primaryGradient : null,
              color: isSelected ? null : context.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : context.textLight.withValues(alpha: 0.18),
                width: 1.4,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color:
                            ColorResource.primaryDark.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_circle_rounded,
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

  Widget _buildFooter() {
    final isSchedule = _deliveryType == 'schedule';
    final hasSelection = _selectedDate != null && _selectedTimeSlot != null;
    final summary = isSchedule && hasSelection
        ? '${_selectedDate!.day} ${_monthNames[_selectedDate!.month - 1]} · $_selectedTimeSlot'
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (summary != null) ...[
              Row(
                children: [
                  Icon(Icons.event_available_rounded,
                      size: 16, color: ColorResource.primaryDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _confirm,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: ColorResource.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              ColorResource.primaryDark.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'confirm_schedule'.tr,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.textLight.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: context.textSecondary, size: 20),
      ),
    );
  }
}
