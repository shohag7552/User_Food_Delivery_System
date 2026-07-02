import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/models/category_model.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/address/screens/add_edit_address_page.dart';
import 'package:appwrite_user_app/app/modules/address/screens/addresses_page.dart';
import 'package:appwrite_user_app/app/modules/address/screens/full_screen_map_page.dart';
import 'package:appwrite_user_app/app/modules/auth/screens/forgot_password_screen.dart';
import 'package:appwrite_user_app/app/modules/auth/screens/login_screen.dart';
import 'package:appwrite_user_app/app/modules/auth/screens/signup_screen.dart';
import 'package:appwrite_user_app/app/modules/cart/screens/cart_page.dart';
import 'package:appwrite_user_app/app/modules/categories/screens/category_products_page.dart';
import 'package:appwrite_user_app/app/modules/categories/screens/category_screen.dart';
import 'package:appwrite_user_app/app/modules/checkout/screens/checkout_page.dart';
import 'package:appwrite_user_app/app/modules/checkout/screens/order_failed_page.dart';
import 'package:appwrite_user_app/app/modules/checkout/screens/order_success_page.dart';
import 'package:appwrite_user_app/app/modules/coupons/screens/coupon_details_screen.dart';
import 'package:appwrite_user_app/app/modules/coupons/screens/coupons_screen.dart';
import 'package:appwrite_user_app/app/modules/dashboard/screens/dashboard_screen.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/full_screen_image_viewer.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/screens/ecommerce_product_detail_page.dart';
import 'package:appwrite_user_app/app/modules/favorites/screens/favorites_screen.dart';
import 'package:appwrite_user_app/app/modules/language/screens/language_screen.dart';
import 'package:appwrite_user_app/app/modules/loyalty_point/screens/loyalty_points_page.dart';
import 'package:appwrite_user_app/app/modules/notification/screens/notification_screen.dart';
import 'package:appwrite_user_app/app/modules/orders/screens/order_delivery_map_page.dart';
import 'package:appwrite_user_app/app/modules/orders/screens/order_detail_page.dart';
import 'package:appwrite_user_app/app/modules/orders/screens/order_history_page.dart';
import 'package:appwrite_user_app/app/modules/orders/screens/orders_page.dart';
import 'package:appwrite_user_app/app/modules/payment/payment_webview_screen.dart';
import 'package:appwrite_user_app/app/modules/policies/screens/policy_content_screen.dart';
import 'package:appwrite_user_app/app/modules/profile/screens/edit_profile_page.dart';
import 'package:appwrite_user_app/app/modules/search/screens/search_page.dart';
import 'package:appwrite_user_app/app/modules/splash/screens/splash_screen.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

/// Route name identifiers used with `context.goNamed` / `context.pushNamed`.
///
/// Using named routes keeps call sites decoupled from the concrete URL
/// structure — change a path in one place (the [GoRoute] below) and every
/// navigation call keeps working.
abstract class RouteNames {
  const RouteNames._();

  static const splash = 'splash';
  static const login = 'login';
  static const signup = 'signup';
  static const forgotPassword = 'forgot-password';
  static const dashboard = 'dashboard';
  static const search = 'search';
  static const categories = 'categories';
  static const category = 'category';
  static const productDetail = 'product-detail';
  static const cart = 'cart';
  static const checkout = 'checkout';
  static const orderSuccess = 'order-success';
  static const orderFailed = 'order-failed';
  static const orders = 'orders';
  static const orderHistory = 'order-history';
  static const orderDetail = 'order-detail';
  static const deliveryMap = 'delivery-map';
  static const editProfile = 'edit-profile';
  static const addresses = 'addresses';
  static const addEditAddress = 'add-edit-address';
  static const favorites = 'favorites';
  static const notifications = 'notifications';
  static const loyalty = 'loyalty-points';
  static const language = 'language';
  static const coupons = 'coupons';
  static const couponDetails = 'coupon-details';
  static const policy = 'policy';
  static const mapPicker = 'map-picker';
  static const imageViewer = 'image-viewer';
  static const payment = 'payment';
}

// ── Argument bundles for routes that carry more than one non-URL value. ──
// Passed through go_router's `extra`; only available for in-app navigation
// (a hard refresh / deep link has `extra == null`, handled per route below).

class PolicyArgs {
  final String title;
  final String htmlContent;
  const PolicyArgs({required this.title, required this.htmlContent});
}

class OrderSuccessArgs {
  final String orderNumber;
  final double totalAmount;
  const OrderSuccessArgs({required this.orderNumber, required this.totalAmount});
}

class OrderFailedArgs {
  final String errorMessage;
  final VoidCallback? onRetry;
  const OrderFailedArgs({required this.errorMessage, this.onRetry});
}

class CouponsArgs {
  final bool isSelectionMode;
  final void Function(CouponModel coupon)? onCouponSelected;
  const CouponsArgs({this.isSelectionMode = false, this.onCouponSelected});
}

class CouponDetailsArgs {
  final CouponModel coupon;
  final bool isSelectionMode;
  final void Function(CouponModel coupon)? onSelect;
  const CouponDetailsArgs({
    required this.coupon,
    this.isSelectionMode = false,
    this.onSelect,
  });
}

class ImageViewerArgs {
  final String imageUrl;
  final String heroTag;
  const ImageViewerArgs({required this.imageUrl, required this.heroTag});
}

class PaymentArgs {
  final String paymentURL;
  final String gatewayName;
  const PaymentArgs({required this.paymentURL, required this.gatewayName});
}

class DeliveryMapArgs {
  final DeliverymanInfo? deliveryman;
  final String businessName;
  final String businessAddress;
  final double businessLatitude;
  final double businessLongitude;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  const DeliveryMapArgs({
    required this.deliveryman,
    required this.businessName,
    required this.businessAddress,
    required this.businessLatitude,
    required this.businessLongitude,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
  });
}

/// Central app router.
///
/// Keeps GetX for state/DI/i18n while go_router owns navigation. Detail pages
/// use a path parameter for their id (clean, deep-linkable URLs) plus `extra`
/// carrying the already-loaded model for instant render; on a cold deep link
/// the page hydrates from the id where possible, otherwise falls back home.
abstract class AppRouter {
  const AppRouter._();

  // Reuse GetX's navigator key so GetX overlays (Get.snackbar / Get.dialog /
  // Get.bottomSheet) resolve against the same navigator go_router drives.
  static final GlobalKey<NavigatorState> rootNavigatorKey = Get.key;

  // Concrete paths (templates for the ones with parameters).
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/';
  static const String search = '/search';
  static const String categories = '/categories';
  static const String categoryPath = '/category/:id';
  static const String productDetailPath = '/product/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String orderFailed = '/order-failed';
  static const String orders = '/orders';
  static const String orderHistory = '/order-history';
  static const String orderDetailPath = '/orders/:id';
  static const String deliveryMap = '/delivery-map';
  static const String editProfile = '/edit-profile';
  static const String addresses = '/addresses';
  static const String addEditAddress = '/addresses/edit';
  static const String favorites = '/favorites';
  static const String notifications = '/notifications';
  static const String loyalty = '/loyalty-points';
  static const String language = '/language';
  static const String coupons = '/coupons';
  static const String couponDetails = '/coupons/details';
  static const String policy = '/policy';
  static const String mapPicker = '/map-picker';
  static const String imageViewer = '/image-viewer';
  static const String payment = '/payment';

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        name: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: dashboard,
        name: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: search,
        name: RouteNames.search,
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: categories,
        name: RouteNames.categories,
        builder: (context, state) => const CategoryScreen(),
      ),
      GoRoute(
        path: categoryPath,
        name: RouteNames.category,
        // Needs the full CategoryModel; no fetch-by-id yet, so a cold deep
        // link without `extra` falls back to the dashboard.
        redirect: (context, state) =>
            state.extra is CategoryModel ? null : dashboard,
        builder: (context, state) =>
            CategoryProductsPage(category: state.extra as CategoryModel),
      ),
      GoRoute(
        path: productDetailPath,
        name: RouteNames.productDetail,
        builder: (context, state) {
          final product = state.extra;
          if (product is ProductModel) {
            return EcommerceProductDetailPage(product: product);
          }
          return _ProductByIdLoader(productId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: cart,
        name: RouteNames.cart,
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: checkout,
        name: RouteNames.checkout,
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: orderSuccess,
        name: RouteNames.orderSuccess,
        redirect: (context, state) =>
            state.extra is OrderSuccessArgs ? null : dashboard,
        builder: (context, state) {
          final args = state.extra as OrderSuccessArgs;
          return OrderSuccessPage(
            orderNumber: args.orderNumber,
            totalAmount: args.totalAmount,
          );
        },
      ),
      GoRoute(
        path: orderFailed,
        name: RouteNames.orderFailed,
        redirect: (context, state) =>
            state.extra is OrderFailedArgs ? null : dashboard,
        builder: (context, state) {
          final args = state.extra as OrderFailedArgs;
          return OrderFailedPage(
            errorMessage: args.errorMessage,
            onRetry: args.onRetry,
          );
        },
      ),
      GoRoute(
        path: orders,
        name: RouteNames.orders,
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: orderHistory,
        name: RouteNames.orderHistory,
        builder: (context, state) => const OrderHistoryPage(),
      ),
      GoRoute(
        path: orderDetailPath,
        name: RouteNames.orderDetail,
        builder: (context, state) => OrderDetailPage(
          orderId: state.pathParameters['id']!,
          initialOrder: state.extra as OrderModel?,
        ),
      ),
      GoRoute(
        path: deliveryMap,
        name: RouteNames.deliveryMap,
        redirect: (context, state) =>
            state.extra is DeliveryMapArgs ? null : dashboard,
        builder: (context, state) {
          final args = state.extra as DeliveryMapArgs;
          return OrderDeliveryMapPage(
            deliveryman: args.deliveryman,
            businessName: args.businessName,
            businessAddress: args.businessAddress,
            businessLatitude: args.businessLatitude,
            businessLongitude: args.businessLongitude,
            deliveryAddress: args.deliveryAddress,
            deliveryLatitude: args.deliveryLatitude,
            deliveryLongitude: args.deliveryLongitude,
          );
        },
      ),
      GoRoute(
        path: editProfile,
        name: RouteNames.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: addresses,
        name: RouteNames.addresses,
        builder: (context, state) => const AddressesPage(),
      ),
      GoRoute(
        path: addEditAddress,
        name: RouteNames.addEditAddress,
        builder: (context, state) =>
            AddEditAddressPage(address: state.extra as AddressModel?),
      ),
      GoRoute(
        path: favorites,
        name: RouteNames.favorites,
        builder: (context, state) => FavoritesScreen(
          isFromMenu: state.uri.queryParameters['fromMenu'] == 'true',
        ),
      ),
      GoRoute(
        path: notifications,
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: loyalty,
        name: RouteNames.loyalty,
        builder: (context, state) => const LoyaltyPointsPage(),
      ),
      GoRoute(
        path: language,
        name: RouteNames.language,
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: coupons,
        name: RouteNames.coupons,
        builder: (context, state) {
          final args = state.extra as CouponsArgs?;
          return CouponsScreen(
            isSelectionMode: args?.isSelectionMode ?? false,
            onCouponSelected: args?.onCouponSelected,
          );
        },
      ),
      GoRoute(
        path: couponDetails,
        name: RouteNames.couponDetails,
        redirect: (context, state) =>
            state.extra is CouponDetailsArgs ? null : coupons,
        builder: (context, state) {
          final args = state.extra as CouponDetailsArgs;
          return CouponDetailsScreen(
            coupon: args.coupon,
            isSelectionMode: args.isSelectionMode,
            onSelect: args.onSelect,
          );
        },
      ),
      GoRoute(
        path: policy,
        name: RouteNames.policy,
        redirect: (context, state) =>
            state.extra is PolicyArgs ? null : dashboard,
        builder: (context, state) {
          final args = state.extra as PolicyArgs;
          return PolicyContentScreen(
            title: args.title,
            htmlContent: args.htmlContent,
          );
        },
      ),
      GoRoute(
        path: mapPicker,
        name: RouteNames.mapPicker,
        builder: (context, state) => FullScreenMapPage(
          initialLocation:
              state.extra as LatLng? ?? const LatLng(23.8103, 90.4125),
        ),
      ),
      GoRoute(
        path: imageViewer,
        name: RouteNames.imageViewer,
        redirect: (context, state) =>
            state.extra is ImageViewerArgs ? null : dashboard,
        builder: (context, state) {
          final args = state.extra as ImageViewerArgs;
          return FullScreenImageViewer(
            imageUrl: args.imageUrl,
            heroTag: args.heroTag,
          );
        },
      ),
      GoRoute(
        path: payment,
        name: RouteNames.payment,
        redirect: (context, state) =>
            state.extra is PaymentArgs ? null : dashboard,
        builder: (context, state) {
          final args = state.extra as PaymentArgs;
          return PaymentWebViewScreen(
            paymentURL: args.paymentURL,
            gatewayName: args.gatewayName,
          );
        },
      ),
    ],
  );
}

/// Hydrates the product detail page from an id when it is opened via a cold
/// deep link (no `extra` model available).
class _ProductByIdLoader extends StatefulWidget {
  final String productId;

  const _ProductByIdLoader({required this.productId});

  @override
  State<_ProductByIdLoader> createState() => _ProductByIdLoaderState();
}

class _ProductByIdLoaderState extends State<_ProductByIdLoader> {
  late final Future<ProductModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = Get.find<ProductController>().getProductById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductModel?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final product = snapshot.data;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                'product_not_found'.tr,
                style: TextStyle(color: ColorResource.textSecondary),
              ),
            ),
          );
        }
        return EcommerceProductDetailPage(product: product);
      },
    );
  }
}
