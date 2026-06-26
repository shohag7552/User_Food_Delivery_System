import 'package:appwrite_user_app/app/helper/model_json_converter.dart';

/// Ecommerce brand (e.g. Nike, Samsung). Name is a multilang JSON map.
class BrandModel {
  final String id;
  final Map<String, dynamic> nameMap;
  final String? description;
  final String? logoUrl;
  final bool isActive;
  final int sortOrder;

  BrandModel({
    required this.id,
    required this.nameMap,
    this.description,
    this.logoUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['\$id'] as String? ?? json['id'] ?? '',
      nameMap: ModelJsonConverter.parseData(json['name'] ?? ''),
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': nameMap,
      'description': description,
      'logo_url': logoUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}
