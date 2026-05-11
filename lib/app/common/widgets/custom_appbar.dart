import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool? showBackButton;
  final Function? onBackButtonPressed;
  const CustomAppbar({super.key, required this.title, this.actions, this.showBackButton = true, this.onBackButtonPressed});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: poppinsBold.copyWith(
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
      ),
      leading: showBackButton! ? IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => onBackButtonPressed ?? Navigator.pop(context),
      ) : null,
      elevation: 0,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size(Get.width, 50);
}
