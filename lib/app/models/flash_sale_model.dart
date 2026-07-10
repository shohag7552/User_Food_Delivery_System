/// A flash sale event (ecommerce module). Whether it is live is derived from
/// the time window — the backend stores no status field.
class FlashSaleModel {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;
  final String? bannerImage;
  final int sortOrder;
  final String moduleType;

  const FlashSaleModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    this.bannerImage,
    this.sortOrder = 0,
    this.moduleType = 'ecommerce',
  });

  /// Live right now: flagged active and inside the [startTime, endTime] window.
  bool get isRunning {
    final now = DateTime.now();
    return isActive && now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Time left until the sale ends (zero when already over).
  Duration get remaining {
    final left = endTime.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  factory FlashSaleModel.fromJson(Map<String, dynamic> json) {
    return FlashSaleModel(
      id: json[r'$id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startTime: DateTime.tryParse(json['start_time'] as String? ?? '')
              ?.toLocal() ??
          DateTime.now(),
      endTime:
          DateTime.tryParse(json['end_time'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
      bannerImage: json['banner_image'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      moduleType: json['module_type'] as String? ?? 'ecommerce',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'is_active': isActive,
      'banner_image': bannerImage,
      'sort_order': sortOrder,
      'module_type': moduleType,
    };
  }

  FlashSaleModel copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
    String? bannerImage,
    int? sortOrder,
    String? moduleType,
  }) {
    return FlashSaleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      bannerImage: bannerImage ?? this.bannerImage,
      sortOrder: sortOrder ?? this.sortOrder,
      moduleType: moduleType ?? this.moduleType,
    );
  }
}
