import 'package:appwrite/appwrite.dart';
import 'package:kikomart_user_app/app/appwrite/appwrite_config.dart';
import 'package:kikomart_user_app/app/appwrite/appwrite_service.dart';
import 'package:kikomart_user_app/app/models/wallet_transaction_model.dart';
import 'package:kikomart_user_app/app/modules/wallet/domain/repository/wallet_repo_interface.dart';

class WalletRepository implements WalletRepoInterface {
  final AppwriteService appwriteService;

  WalletRepository({required this.appwriteService});

  @override
  Future<List<WalletTransactionModel>> getTransactions(
    String userId, {
    required int limit,
    required int offset,
  }) async {
    final response = await appwriteService.listTable(
      tableId: AppwriteConfig.walletTransactionsCollection,
      queries: [
        Query.equal('user_id', userId),
        Query.orderDesc('created_at'),
        Query.limit(limit),
        Query.offset(offset),
      ],
    );

    return response.rows
        .map((row) => WalletTransactionModel.fromJson(row.data))
        .toList();
  }
}
