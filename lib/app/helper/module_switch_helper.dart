import 'package:appwrite_user_app/app/controllers/banner_controller.dart';
import 'package:appwrite_user_app/app/controllers/brand_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/controllers/flash_sale_controller.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:get/get.dart';

/// Switches the active storefront module and refreshes module-scoped data so
/// every tab reflects the new module.
class ModuleSwitchHelper {
  static Future<void> switchTo(String target) async {
    final moduleController = Get.find<ModuleController>();
    if (!moduleController.isModuleEnabled(target) ||
        moduleController.activeModule == target) {
      return;
    }

    // Drop cached lists first so the incoming storefront never flashes the
    // previous module's data (repos read the active module at query time).
    Get.find<ProductController>().clearForModuleSwitch();
    Get.find<CategoryController>().clearForModuleSwitch();
    Get.find<BannerController>().clearForModuleSwitch();
    if (Get.isRegistered<BrandController>()) {
      Get.find<BrandController>().clearForModuleSwitch();
    }
    if (Get.isRegistered<FlashSaleController>()) {
      Get.find<FlashSaleController>().clearForModuleSwitch();
    }

    // Flip the module — HomeModuleView swaps to the other storefront, which
    // loads its own lists on mount (caches are now empty).
    await moduleController.switchModule(target);

    // Reload data the home views don't own.
    Get.find<CartController>().getCartItems();
    Get.find<OrderController>().fetchUserOrders(refresh: true);
  }
}
