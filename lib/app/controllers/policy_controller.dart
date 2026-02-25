import 'package:appwrite_user_app/app/models/privacy_policy_model.dart';
import 'package:appwrite_user_app/app/modules/policies/domain/repository/policy_repo_interface.dart';
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
      _error = 'Failed to load content. Please try again.';
      _isLoading = false;
      update();
    }
  }
}
