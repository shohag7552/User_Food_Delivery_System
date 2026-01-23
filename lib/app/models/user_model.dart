class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final double walletBalance;
  final bool isActive;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'customer',
    this.walletBalance = 0.0,
    this.isActive = true,
    this.profileImageUrl,
  });

  // Get initials from name for avatar placeholder
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // Create copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    double? walletBalance,
    bool? isActive,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      walletBalance: walletBalance ?? this.walletBalance,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  // Create from JSON (Appwrite document)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['\$id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      walletBalance: (json['wallet_balance'] ?? 0.0).toDouble(),
      isActive: json['is_active'] ?? true,
      profileImageUrl: json['profile_image_url'],
    );
  }

  // Convert to JSON for Appwrite
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'wallet_balance': walletBalance,
      'is_active': isActive,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
    };
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, phone: $phone, role: $role)';
  }
}
