import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/splash_controller.dart';
import 'package:appwrite_user_app/app/modules/auth/screens/login_screen.dart';
import 'package:appwrite_user_app/app/modules/dashboard/screens/dashboard_screen.dart';
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

    Future.delayed(const Duration(milliseconds: 500), () async {
      // Navigate to the next screen after the splash duration
      if(!mounted) return;

      bool isLoggedIn = await Get.find<AuthController>().isAlreadyLoggedIn();
      print('Checking login status in Splash Screen: $isLoggedIn');
      
      if(isLoggedIn) {
        print('-------------User is logged in, fetching settings...');
        
        // Fetch business and store setup data
        bool settingsFetched = await Get.find<SplashController>().fetchSettings();
        
        if(settingsFetched) {
          print('Settings fetched successfully, navigating to Dashboard');
          Get.offAll(() => DashboardScreen());
        } else {
          print('Failed to fetch settings');
          // You can show an error dialog or navigate to an error screen
          Get.offAll(() => DashboardScreen()); // Navigate anyway for now
        }
      } else {
        Get.offAll(() => LoginScreen());
      }
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
