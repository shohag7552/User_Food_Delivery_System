import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kikomart_user_app/app/controllers/auth_controller.dart';
import 'package:kikomart_user_app/app/controllers/order_controller.dart';
import 'package:kikomart_user_app/app/models/order_model.dart';
import 'package:kikomart_user_app/app/modules/auth/domain/repository/auth_repo_interface.dart';
import 'package:kikomart_user_app/app/modules/checkout/domain/repository/order_repo_interface.dart';

class _AuthRepo extends Fake implements AuthRepoInterface {
  @override
  Future<bool> isLoggedIn() async => true;
}

class _Order extends Fake implements OrderModel {
  _Order(this.status);
  @override
  final String status;
}

/// Answers each status only when the test completes that status's request.
class _OrderRepo extends Fake implements OrderRepoInterface {
  final pending = <String, Completer<List<OrderModel>>>{};

  @override
  Future<List<OrderModel>> getUserOrders({
    String? status,
    String? searchQuery,
    int limit = 10,
    int offset = 0,
  }) => (pending[status ?? 'all'] = Completer()).future;
}

void main() {
  late _OrderRepo repo;
  late OrderController controller;

  setUp(() async {
    Get.testMode = true;
    final auth = Get.put(AuthController(authRepoInterface: _AuthRepo()));
    await auth.isAlreadyLoggedIn();
    repo = _OrderRepo();
    controller = OrderController(orderRepoInterface: repo);
  });

  tearDown(Get.reset);

  test('switching status clears the old list and shows loading', () async {
    controller.fetchUserOrders(refresh: true);
    repo.pending['all']!.complete([_Order('pending')]);
    await pumpEventQueue();
    expect(controller.orders, hasLength(1));

    controller.filterByStatus('delivered');
    expect(controller.orders, isEmpty);
    expect(controller.isLoading, isTrue);
  });

  test('a slower, older status response never overwrites the latest', () async {
    controller.filterByStatus('pending');
    controller.filterByStatus('delivered');

    repo.pending['delivered']!.complete([_Order('delivered')]);
    await pumpEventQueue();
    repo.pending['pending']!.complete([_Order('pending'), _Order('pending')]);
    await pumpEventQueue();

    expect(controller.orders.map((o) => o.status), ['delivered']);
    expect(controller.isLoading, isFalse);
  });
}
