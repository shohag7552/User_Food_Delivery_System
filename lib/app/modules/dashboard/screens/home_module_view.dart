import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/modules/dashboard/screens/home_page.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/screens/ecommerce_home_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Picks the storefront for the Home tab based on the active module.
/// Food stores see the existing [HomePage] unchanged.
class HomeModuleView extends StatelessWidget {
  const HomeModuleView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ModuleController>(
      builder: (module) =>
          module.isEcommerce ? const EcommerceHomeView() : const HomePage(),
    );
  }
}
