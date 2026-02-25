import 'package:appwrite_user_app/app/models/privacy_policy_model.dart';

abstract class PolicyRepoInterface {
  Future<PrivacyPolicyModel> getPolicies();
}
