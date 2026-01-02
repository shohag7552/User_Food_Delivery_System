import 'dart:convert';
import 'package:flutter/material.dart';

/// Represents a single time range (e.g., 9:00 AM - 12:00 PM)
class TimeSlot {
  final TimeOfDay openTime;
  final TimeOfDay closeTime;

  TimeSlot({
    required this.openTime,
    required this.closeTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      openTime: TimeOfDay(
        hour: json['open_hour'] as int,
        minute: json['open_minute'] as int,
      ),
      closeTime: TimeOfDay(
        hour: json['close_hour'] as int,
        minute: json['close_minute'] as int,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'open_hour': openTime.hour,
        'open_minute': openTime.minute,
        'close_hour': closeTime.hour,
        'close_minute': closeTime.minute,
      };

  TimeSlot copyWith({
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
  }) {
    return TimeSlot(
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  String formatTime(BuildContext context) {
    return '${openTime.format(context)} - ${closeTime.format(context)}';
  }
}

/// Represents a day's business hours (can have multiple time slots)
class DaySchedule {
  final bool isOpen;
  final List<TimeSlot> timeSlots;

  DaySchedule({
    required this.isOpen,
    required this.timeSlots,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      isOpen: json['is_open'] as bool,
      timeSlots: (json['time_slots'] as List)
          .map((e) => TimeSlot.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'is_open': isOpen,
        'time_slots': timeSlots.map((e) => e.toJson()).toList(),
      };

  DaySchedule copyWith({
    bool? isOpen,
    List<TimeSlot>? timeSlots,
  }) {
    return DaySchedule(
      isOpen: isOpen ?? this.isOpen,
      timeSlots: timeSlots ?? this.timeSlots,
    );
  }

  /// Creates a default open day schedule with one time slot
  factory DaySchedule.defaultOpen() {
    return DaySchedule(
      isOpen: true,
      timeSlots: [
        TimeSlot(
          openTime: const TimeOfDay(hour: 9, minute: 0),
          closeTime: const TimeOfDay(hour: 18, minute: 0),
        ),
      ],
    );
  }

  /// Creates a closed day schedule
  factory DaySchedule.closed() {
    return DaySchedule(
      isOpen: false,
      timeSlots: [],
    );
  }
}

/// Full week business hours schedule
class WeeklyBusinessHours {
  /// Schedule for each day: 0=Sunday, 1=Monday, ..., 6=Saturday
  final Map<int, DaySchedule> schedule;

  WeeklyBusinessHours({required this.schedule});

  /// Day names for display
  static const List<String> dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  /// Short day names
  static const List<String> shortDayNames = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  factory WeeklyBusinessHours.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    final Map<int, DaySchedule> schedule = {};
    for (int i = 0; i < 7; i++) {
      if (json.containsKey(i.toString())) {
        schedule[i] = DaySchedule.fromJson(json[i.toString()]);
      }
    }
    return WeeklyBusinessHours(schedule: schedule);
  }

  String toJsonString() {
    final Map<String, dynamic> json = {};
    schedule.forEach((key, value) {
      json[key.toString()] = value.toJson();
    });
    return jsonEncode(json);
  }

  WeeklyBusinessHours copyWith({Map<int, DaySchedule>? schedule}) {
    return WeeklyBusinessHours(
      schedule: schedule ?? Map.from(this.schedule),
    );
  }

  /// Creates a default weekly schedule (Mon-Fri open, Sat-Sun closed)
  factory WeeklyBusinessHours.defaultSchedule() {
    return WeeklyBusinessHours(
      schedule: {
        0: DaySchedule.closed(), // Sunday
        1: DaySchedule.defaultOpen(), // Monday
        2: DaySchedule.defaultOpen(), // Tuesday
        3: DaySchedule.defaultOpen(), // Wednesday
        4: DaySchedule.defaultOpen(), // Thursday
        5: DaySchedule.defaultOpen(), // Friday
        6: DaySchedule.closed(), // Saturday
      },
    );
  }

  /// Get schedule for a specific day
  DaySchedule getDay(int day) {
    return schedule[day] ?? DaySchedule.closed();
  }

  /// Update a specific day's schedule
  WeeklyBusinessHours updateDay(int day, DaySchedule daySchedule) {
    final newSchedule = Map<int, DaySchedule>.from(schedule);
    newSchedule[day] = daySchedule;
    return WeeklyBusinessHours(schedule: newSchedule);
  }
}
