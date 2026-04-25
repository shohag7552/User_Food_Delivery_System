import 'package:appwrite_user_app/app/models/loyalty_history_model.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/models/user_model.dart';

abstract class LoyaltyRepoInterface {
  Future<List<LoyaltyHistoryModel>> getLoyaltyHistory(String userId);

  Future<UserModel> convertPointsToWallet({
    required UserModel user,
    required int points,
    required double conversionRate,
  });

  Future<UserModel> awardDeliveredOrderPoints({
    required UserModel user,
    required OrderModel order,
    required double earningRate,
  });

  Future<UserModel> syncDeliveredOrderPoints({
    required UserModel user,
    required double earningRate,
  });
}
