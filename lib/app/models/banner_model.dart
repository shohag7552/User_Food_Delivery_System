class BannerModel {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String actionType; // 'none', 'product', 'category', 'url'
  final String? actionValue;
  final bool isActive;
  final int sortOrder;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    required this.actionType,
    this.actionValue,
    required this.isActive,
    required this.sortOrder,
  });

  // Factory to convert Appwrite JSON -> Dart Object
  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['\$id'], // Appwrite uses $id
      imageUrl: json['image_url'],
      title: json['title'],
      subtitle: json['subtitle'],
      actionType: json['action_type'],
      actionValue: json['action_value'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  // To send back to Appwrite (for admin functionality)
  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'action_type': actionType,
      'action_value': actionValue,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  // Check if banner has an action
  bool get hasAction => actionType != 'none' && actionValue != null && actionValue!.isNotEmpty;
}
