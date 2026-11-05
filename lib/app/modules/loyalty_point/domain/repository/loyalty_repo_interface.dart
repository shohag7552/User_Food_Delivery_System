import 'package:kikomart_user_app/app/models/loyalty_history_model.dart';
import 'package:kikomart_user_app/app/models/user_model.dart';

abstract class LoyaltyRepoInterface {
  Future<List<LoyaltyHistoryModel>> getLoyaltyHistory(String userId);

  Future<UserModel> convertPointsToWallet({
    required UserModel user,
    required int points,
    required double conversionRate,
  });
}
