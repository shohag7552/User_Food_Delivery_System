import 'dart:developer';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/privacy_policy_model.dart';
import 'package:appwrite_user_app/app/modules/policies/domain/repository/policy_repo_interface.dart';

class PolicyRepository implements PolicyRepoInterface {
  final AppwriteService appwriteService;

  PolicyRepository({required this.appwriteService});

  @override
  Future<PrivacyPolicyModel> getPolicies() async {
    try {
      final result = await appwriteService.listTable(
        tableId: AppwriteConfig.privacyPolicyCollection,
      );

      if (result.rows.isEmpty) {
        return PrivacyPolicyModel.empty();
      }

      return PrivacyPolicyModel.fromJson(result.rows.first.data);
    } catch (e) {
      log('Error fetching policies: $e');
      return PrivacyPolicyModel.empty();
    }
  }
}
