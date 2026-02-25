class PrivacyPolicyModel {
  final String id;
  final String privacyPolicyHtml;
  final String termsAndConditionsHtml;
  final String aboutUsHtml;

  PrivacyPolicyModel({
    required this.id,
    required this.privacyPolicyHtml,
    required this.termsAndConditionsHtml,
    required this.aboutUsHtml,
  });

  factory PrivacyPolicyModel.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicyModel(
      id: json['\$id'] ?? '',
      privacyPolicyHtml: json['privacy_policy_html'] ?? '',
      termsAndConditionsHtml: json['terms_and_conditions_html'] ?? '',
      aboutUsHtml: json['about_us_html'] ?? '',
    );
  }

  /// Returns an empty model when no data is available
  factory PrivacyPolicyModel.empty() {
    return PrivacyPolicyModel(
      id: '',
      privacyPolicyHtml: '',
      termsAndConditionsHtml: '',
      aboutUsHtml: '',
    );
  }
}
