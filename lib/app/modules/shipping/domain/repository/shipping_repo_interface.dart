import 'package:appwrite_user_app/app/models/shipping_method_model.dart';

abstract class ShippingRepoInterface {
  /// Active shipping methods, ordered by sort order.
  Future<List<ShippingMethodModel>> getShippingMethods();
}
