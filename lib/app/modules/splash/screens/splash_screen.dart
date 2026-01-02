import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/modules/auth/screens/login_screen.dart';
import 'package:appwrite_user_app/app/modules/dashboard/screens/dashboard_screen.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 1), () async {
      // Navigate to the next screen after the splash duration
      if(!mounted) return;

      if(await Get.find<AuthController>().isAlreadyLoggedIn()) {
        Get.offAll(DashboardScreen());
      } else {
        Get.offAll(() => LoginScreen());
      }
      // Navigator.pushReplacementNamed(context, '/home');
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Splash Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
