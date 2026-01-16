import 'dart:convert';

import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/controllers/coupon_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/controllers/banner_controller.dart';
import 'package:appwrite_user_app/app/controllers/localization_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/address_controller.dart';
import 'package:appwrite_user_app/app/modules/auth/domain/repository/auth_repo_interface.dart';
import 'package:appwrite_user_app/app/modules/auth/domain/repository/auth_repository.dart';
import 'package:appwrite_user_app/app/modules/categories/domain/repository/category_repo_interface.dart';
import 'package:appwrite_user_app/app/modules/categories/domain/repository/category_repository.dart';
import 'package:appwrite_user_app/app/modules/coupons/domain/repository/coupon_repo_interface.dart';
import 'package:appwrite_user_app/app/modules/coupons/domain/repository/coupon_repository.dart';
import 'package:appwrite_user_app/app/modules/products/domain/repository/product_repo_interface.dart';
import 'package:appwrite_user_app/app/modules/products/domain/repository/product_repository.dart';
import 'package:appwrite_user_app/app/modules/banners/domain/repository/banner_repo_interface.dart';
import 'package:appwrite_user_app/app/modules/banners/domain/repository/banner_repository.dart';
import 'package:appwrite_user_app/app/modules/cart/domain/repository/cart_repo_interface.dart';
import 'package:appwrite_user_app/app/modules/cart/domain/repository/cart_repository.dart';
import 'package:appwrite_user_app/app/modules/address/domain/repository/address_repo_interface.dart';
import 'package:appwrite_user_app/app/modules/address/domain/repository/address_repository.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, Map<String, String>>> initializeDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  Get.lazyPut(() => sharedPreferences, fenix: true);

  Get.lazyPut(() => LocalizationController(sharedPreferences: Get.find()));
  Get.lazyPut(() => AppwriteService());
  // Get.lazyPut(() => ApiService(appBaseUrl: AppUrls.baseUrl, sharedPreferences: sharedPreferences));

  /// Repository Initialization
  AuthRepoInterface loginRepoInterface = AuthRepository(sharedPreferences: sharedPreferences, appwriteService: Get.find());
  Get.lazyPut(() => loginRepoInterface);

  CategoryRepoInterface categoryRepoInterface = CategoryRepository(appwriteService: Get.find());
  Get.lazyPut(() => categoryRepoInterface);

  CouponRepoInterface couponRepoInterface = CouponRepository(appwriteService: Get.find());
  Get.lazyPut(() => couponRepoInterface);

  ProductRepoInterface productRepoInterface = ProductRepository(appwriteService: Get.find());
  Get.lazyPut(() => productRepoInterface);

  BannerRepoInterface bannerRepoInterface = BannerRepository(appwriteService: Get.find());
  Get.lazyPut(() => bannerRepoInterface);

  CartRepoInterface cartRepoInterface = CartRepository(appwriteService: Get.find());
  Get.lazyPut(() => cartRepoInterface);

  AddressRepoInterface addressRepoInterface = AddressRepository(appwriteService: Get.find());
  Get.lazyPut(() => addressRepoInterface);


  /// Controller Initialization
  Get.lazyPut(() => AuthController(authRepoInterface: Get.find()));
  Get.lazyPut(() => CategoryController(categoryRepoInterface: Get.find()));
  Get.lazyPut(() => CouponController(couponRepoInterface: Get.find()));
  Get.lazyPut(() => ProductController(productRepoInterface: Get.find()));
  Get.lazyPut(() => BannerController(bannerRepoInterface: Get.find()));
  Get.lazyPut(() => CartController(cartRepoInterface: Get.find()));
  Get.lazyPut(() => AddressController(addressRepoInterface: Get.find()));


  /// Retrieving localized data
  Map<String, Map<String, String>> languages = {};
  // for(LanguageModel languageModel in Constants.languages) {
  //   String jsonStringValues =  await rootBundle.loadString('assets/language/${languageModel.languageCode}.json');
  //   Map<String, dynamic> mappedJson = jsonDecode(jsonStringValues);
  //   Map<String, String> json = {};
  //   mappedJson.forEach((key, value) {
  //     json[key] = value.toString();
  //   });
  //   languages['${languageModel.languageCode}_${languageModel.countryCode}'] = json;
  // }
  return languages;
}