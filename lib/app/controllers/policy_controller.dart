import 'dart:developer';

import 'package:kikomart_user_app/app/models/privacy_policy_model.dart';
import 'package:kikomart_user_app/app/modules/policies/domain/repository/policy_repo_interface.dart';
import 'package:get/get.dart';

class PolicyController extends GetxController {
  final PolicyRepoInterface policyRepoInterface;

  PolicyController({required this.policyRepoInterface});

  PrivacyPolicyModel? _policies;
  PrivacyPolicyModel? get policies => _policies;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchPolicies() async {
    _isLoading = true;
    _error = null;
    // update();

    try {
      _policies = await policyRepoInterface.getPolicies();
    } catch (e) {
      log('Error loading policies: $e');
      _error = 'failed_to_load_content_try_again'.tr;
      _isLoading = false;
      update();
    }
  }
}
