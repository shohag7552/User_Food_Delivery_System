import 'package:kikomart_user_app/app/models/wallet_transaction_model.dart';

abstract class WalletRepoInterface {
  /// The customer's wallet history, newest first, one page at a time.
  Future<List<WalletTransactionModel>> getTransactions(
    String userId, {
    required int limit,
    required int offset,
  });
}
