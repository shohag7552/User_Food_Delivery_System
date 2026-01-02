class StoreSetupModel {
  final String? id;
  final String storeName;
  final String description;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String phone;
  final String email;
  final String? website;
  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? logoUrl;
  final String? coverUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StoreSetupModel({
    this.id,
    required this.storeName,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    required this.email,
    this.website,
    this.facebook,
    this.instagram,
    this.twitter,
    this.logoUrl,
    this.coverUrl,
    this.createdAt,
    this.updatedAt,
  });

  // Factory to convert Appwrite JSON -> Dart Object
  factory StoreSetupModel.fromJson(Map<String, dynamic> json) {
    return StoreSetupModel(
      id: json['\$id'],
      storeName: json['store_name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zip_code'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      website: json['website'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      twitter: json['twitter'],
      logoUrl: json['logo_url'],
      coverUrl: json['cover_url'],
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'])
          : null,
      updatedAt: json['\$updatedAt'] != null
          ? DateTime.parse(json['\$updatedAt'])
          : null,
    );
  }

  // To send back to Appwrite
  Map<String, dynamic> toJson() {
    return {
      'store_name': storeName,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'phone': phone,
      'email': email,
      if (website != null && website!.isNotEmpty) 'website': website,
      if (facebook != null && facebook!.isNotEmpty) 'facebook': facebook,
      if (instagram != null && instagram!.isNotEmpty) 'instagram': instagram,
      if (twitter != null && twitter!.isNotEmpty) 'twitter': twitter,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logo_url': logoUrl,
      if (coverUrl != null && coverUrl!.isNotEmpty) 'cover_url': coverUrl,
    };
  }

  // Create a copy with modified fields
  StoreSetupModel copyWith({
    String? id,
    String? storeName,
    String? description,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
    String? email,
    String? website,
    String? facebook,
    String? instagram,
    String? twitter,
    String? logoUrl,
    String? coverUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoreSetupModel(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      twitter: twitter ?? this.twitter,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
