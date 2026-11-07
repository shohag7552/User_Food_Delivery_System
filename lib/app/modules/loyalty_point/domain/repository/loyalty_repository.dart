import 'package:appwrite/appwrite.dart';
import 'package:kikomart_user_app/app/appwrite/appwrite_config.dart';
import 'package:kikomart_user_app/app/appwrite/appwrite_service.dart';
import 'package:kikomart_user_app/app/models/loyalty_history_model.dart';
import 'package:kikomart_user_app/app/models/user_model.dart';
import 'package:kikomart_user_app/app/modules/loyalty_point/domain/repository/loyalty_repo_interface.dart';

class LoyaltyRepository implements LoyaltyRepoInterface {
  final AppwriteService appwriteService;

  LoyaltyRepository({required this.appwriteService});

  @override
  Future<List<LoyaltyHistoryModel>> getLoyaltyHistory(String userId) async {
    final response = await appwriteService.listTable(
      tableId: AppwriteConfig.loyaltyHistoryCollection,
      queries: [Query.equal('user_id', userId), Query.orderDesc('\$createdAt')],
    );

    return response.rows
        .map((row) => LoyaltyHistoryModel.fromJson(row.data))
        .toList();
  }

  // Points for delivered orders are awarded by the backend function's orders
  // event, whoever marks the order delivered.

  @override
  Future<UserModel> convertPointsToWallet({
    required UserModel user,
    required int points,
    required double conversionRate,
  }) async {
    if (points <= 0 || points > user.loyaltyPoints || conversionRate <= 0) {
      throw Exception('Invalid loyalty point conversion');
    }

    // Through the backend: points and wallet move in atomic steps on the
    // server, at the store's current rate, and the history row is written
    // there too.
    final updated = await appwriteService.callBackend('convert_loyalty', {
      'points': points,
    });
    return UserModel.fromJson(updated);
  }
}
