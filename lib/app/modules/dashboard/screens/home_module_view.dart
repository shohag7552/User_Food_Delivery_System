import 'package:appwrite_user_app/app/common/widgets/floating_module_switcher.dart';
import 'package:appwrite_user_app/app/common/widgets/web_module_switcher.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/modules/dashboard/screens/home_page.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/screens/ecommerce_home_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Picks the storefront for the Home tab based on the active module, and floats
/// the Food/Shop switcher over it (only when both are enabled). Food stores see
/// the existing [HomePage] unchanged.
///
/// The switcher itself differs by shell, because the input does. A finger gets
/// the draggable handle it can move out of its own way; a pointer gets a
/// control that states both storefronts and switches on one click, and never
/// moves so it is findable twice.
class HomeModuleView extends StatelessWidget {
  const HomeModuleView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool useWebShell = WebTopNav.isEnabled(context);

    return Stack(
      children: [
        GetBuilder<ModuleController>(
          builder: (module) =>
              module.isEcommerce ? const EcommerceHomeView() : const HomePage(),
        ),
        Positioned.fill(
          child: useWebShell
              ? const WebModuleSwitcher()
              : const FloatingModuleSwitcher(),
        ),
      ],
    );
  }
}
