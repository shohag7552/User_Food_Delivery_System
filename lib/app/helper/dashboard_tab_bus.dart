import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The dashboard's tabs as URL identities.
///
/// The active tab is encoded in the dashboard's URL (`/?tab=cart`), so the
/// browser address bar always names the visible screen, tab links are
/// shareable/deep-linkable, and browser back/forward moves between tabs.
/// The dashboard reads the parameter on build (cold deep links) and in
/// `didUpdateWidget` (when already alive), so [open] works from any stack.
class DashboardTabs {
  DashboardTabs._();

  /// URL slugs, indexed by tab position in the dashboard's PageView.
  static const List<String> names = [
    'home',
    'favorites',
    'cart',
    'orders',
    'profile',
  ];

  /// Tab index for a `?tab=` value; null when absent/unknown.
  static int? indexFromName(String? name) {
    final index = names.indexOf(name ?? '');
    return index == -1 ? null : index;
  }

  /// Navigate to the dashboard with [index]'s tab encoded in the URL.
  static void open(BuildContext context, int index) {
    context.goNamed(
      RouteNames.dashboard,
      queryParameters: {'tab': names[index]},
    );
  }
}
