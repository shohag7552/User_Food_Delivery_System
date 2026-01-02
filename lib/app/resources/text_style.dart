import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// final poppinsRegular = TextStyle(
//   fontFamily: 'Poppins',
//   fontWeight: FontWeight.w400,
//   // color: Theme.of(Get.context!).textTheme.bodyMedium!.color,
//   fontSize: FontSize.fontSizeDefault,
// );

final poppinsRegular = GoogleFonts.inter(
  fontWeight: FontWeight.w400,
  fontSize: Constants.fontSizeDefault,
);

final poppinsMedium = GoogleFonts.inter(
  fontWeight: FontWeight.w500,
  fontSize: Constants.fontSizeDefault,
);

final poppinsBold = GoogleFonts.inter(
  fontWeight: FontWeight.w700,
  fontSize: Constants.fontSizeDefault,
);

final robotoBlack = GoogleFonts.inter(
  fontWeight: FontWeight.w900,
  fontSize: Constants.fontSizeDefault,
);