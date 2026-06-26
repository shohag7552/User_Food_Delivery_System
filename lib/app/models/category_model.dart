import 'package:appwrite_user_app/app/helper/model_json_converter.dart';

class CategoryModel {
  final String id;
  final Map<String, dynamic> nameMap;
  final Map<String, dynamic> descriptionMap;
  final String? imagePath;
  final String moduleType; // 'food' | 'ecommerce'
  final String? parentId; // ecommerce nested categories (null = top level)
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.nameMap,
    required this.descriptionMap,
    this.imagePath,
    this.moduleType = 'food',
    this.parentId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': nameMap,
      'description': descriptionMap,
      'image_path': imagePath,
      'module_type': moduleType,
      'parent_id': parentId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['\$id'] as String? ?? json['id']??'',
      nameMap: ModelJsonConverter.parseData(json['name'] ?? ''),
      descriptionMap: ModelJsonConverter.parseData(json['description'] ?? ''),
      imagePath: json['image_path'] as String?,
      moduleType: json['module_type'] as String? ?? 'food',
      parentId: json['parent_id'] as String?,
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'] as String)
          : null,
    );
  }

  // Copy with method for updating
  CategoryModel copyWith({
    String? id,
    Map<String, dynamic>? name,
    Map<String, dynamic>? description,
    String? imagePath,
    String? moduleType,
    String? parentId,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      nameMap: name ?? nameMap,
      descriptionMap: description ?? descriptionMap,
      imagePath: imagePath ?? this.imagePath,
      moduleType: moduleType ?? this.moduleType,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
