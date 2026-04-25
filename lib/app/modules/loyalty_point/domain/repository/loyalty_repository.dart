import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/loyalty_history_model.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/models/user_model.dart';
import 'package:appwrite_user_app/app/modules/loyalty_point/domain/repository/loyalty_repo_interface.dart';

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

  @override
  Future<UserModel> syncDeliveredOrderPoints({
    required UserModel user,
    required double earningRate,
  }) async {
    if (earningRate <= 0) {
      return user;
    }

    final response = await appwriteService.listTable(
      tableId: AppwriteConfig.ordersCollection,
      queries: [
        Query.equal('customer_id', user.id),
        Query.equal('status', 'delivered'),
        Query.limit(100),
      ],
    );

    var currentUser = user;
    for (final row in response.rows) {
      currentUser = await awardDeliveredOrderPoints(
        user: currentUser,
        order: OrderModel.fromJson(row.data),
        earningRate: earningRate,
      );
    }

    return currentUser;
  }

  @override
  Future<UserModel> awardDeliveredOrderPoints({
    required UserModel user,
    required OrderModel order,
    required double earningRate,
  }) async {
    if (order.status != 'delivered' || earningRate <= 0) {
      return user;
    }

    final alreadyAwarded = await _hasHistoryForOrder(
      userId: user.id,
      orderId: order.id,
    );
    if (alreadyAwarded) {
      return user;
    }

    final earnedPoints = (order.totalAmount * earningRate).floor();
    if (earnedPoints <= 0) {
      return user;
    }

    final updatedUser = user.copyWith(
      loyaltyPoints: user.loyaltyPoints + earnedPoints,
    );

    final response = await appwriteService.updateTable(
      tableId: AppwriteConfig.usersCollection,
      rowId: user.id,
      data: {'loyalty_points': updatedUser.loyaltyPoints},
    );

    await _createHistory(
      userId: user.id,
      orderId: order.id,
      type: 'earned',
      title: 'Order reward',
      description: 'Earned from order #${order.orderNumber}',
      points: earnedPoints,
      walletAmount: 0,
    );

    return UserModel.fromJson(response.data);
  }

  @override
  Future<UserModel> convertPointsToWallet({
    required UserModel user,
    required int points,
    required double conversionRate,
  }) async {
    if (points <= 0 || points > user.loyaltyPoints || conversionRate <= 0) {
      throw Exception('Invalid loyalty point conversion');
    }

    final walletAmount = points * conversionRate;
    final updatedPoints = user.loyaltyPoints - points;
    final updatedWalletBalance = user.walletBalance + walletAmount;

    final response = await appwriteService.updateTable(
      tableId: AppwriteConfig.usersCollection,
      rowId: user.id,
      data: {
        'loyalty_points': updatedPoints,
        'wallet_balance': updatedWalletBalance,
      },
    );

    await _createHistory(
      userId: user.id,
      type: 'converted',
      title: 'Wallet conversion',
      description: 'Converted to wallet balance',
      points: points,
      walletAmount: walletAmount,
    );

    return UserModel.fromJson(response.data);
  }

  Future<bool> _hasHistoryForOrder({
    required String userId,
    required String orderId,
  }) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.loyaltyHistoryCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('order_id', orderId),
          Query.equal('type', 'earned'),
          Query.limit(1),
        ],
      );
      return response.rows.isNotEmpty;
    } catch (e) {
      log('Error checking loyalty history for order: $e');
      rethrow;
    }
  }

  Future<void> _createHistory({
    required String userId,
    String? orderId,
    required String type,
    required String title,
    required String description,
    required int points,
    required double walletAmount,
  }) async {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'type': type,
      'title': title,
      'description': description,
      'points': points,
      'wallet_amount': walletAmount,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (orderId != null) {
      data['order_id'] = orderId;
    }

    await appwriteService.createRow(
      collectionId: AppwriteConfig.loyaltyHistoryCollection,
      data: data,
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.write(Role.user(userId)),
      ],
    );
  }
}
