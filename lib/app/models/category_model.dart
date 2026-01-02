class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String? imagePath;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_path': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['\$id'] as String? ?? json['id']??'',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imagePath: json['image_path'] as String?,
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'] as String)
          : null,
    );
  }

  // Copy with method for updating
  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
