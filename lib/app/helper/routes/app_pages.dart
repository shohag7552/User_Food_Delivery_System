
import 'package:appwrite_user_app/app/modules/splash/screens/splash_screen.dart';
import 'package:get/get.dart';

abstract class AppPages {
  const AppPages._();

  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const home = '/home';
  static const forgetPassword = '/forget-pass';
  static const verificationScreen = '/verification';
  static const dashboard = '/dashboard';

  static String goToSplashPage() => splash;
  static String goToSignInPage() => signIn;
  static String goToHomePage() => home;
  static String goToForgetPassPage() => forgetPassword;
  static String goToVerificationPage() => verificationScreen;
  static String goToDashboardPage() => dashboard;

  static final routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
    ),
    // GetPage(
    //   name: signIn,
    //   page: () => const SignInScreen(),
    // ),
    // GetPage(
    //   name: home,
    //   page: () => const HomeScreen(),
    // ),
    // GetPage(
    //   name: forgetPassword,
    //   page: () => const ForgotPasswordScreen(),
    // ),
    // GetPage(
    //   name: dashboard,
    //   page: () => const DashboardScreen(),
    // ),
  ];
}
