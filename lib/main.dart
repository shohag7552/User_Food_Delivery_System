import 'package:appwrite_user_app/app/controllers/localization_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_pages.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/messages.dart';
import 'package:appwrite_user_app/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';

import 'app/resources/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Stripe
  Stripe.publishableKey = Constants.stripePublishableKey;
  
  await Global.init().then((languages) => runApp(MyApp(languages: languages)));
}

class MyApp extends StatelessWidget {
  final Map<String, Map<String, String>> languages;
  const MyApp({super.key, required this.languages});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (localizeController) {
        return GetMaterialApp(
          title: Constants.appName,
          debugShowCheckedModeBanner: false,
          theme: localizeController.darkTheme ? darkTheme : lightTheme,
          // theme: darkTheme,
          locale: localizeController.locale,
          translations: Messages(languages: languages),
          fallbackLocale: Locale(Constants.languages[0].languageCode!, Constants.languages[0].countryCode),
          getPages: AppPages.routes,
          // home: VerificationScreen(tempToken: '', registrationModel: null),
          initialRoute: AppPages.goToSplashPage(),
        );
      }
    );
  }
}
