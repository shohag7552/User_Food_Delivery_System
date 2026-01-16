import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
        backgroundColor: ColorResource.primaryDark,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: ColorResource.primaryDark,
              child: Icon(
                Icons.person,
                size: 60,
                color: ColorResource.textWhite,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Profile Page',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeExtraLarge,
                color: ColorResource.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your profile information will appear here',
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
