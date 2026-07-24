import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Roboto (the primary UI font) doesn't include Arabic glyphs, so Arabic text
/// would otherwise fall back to an arbitrary system font. Noto Sans Arabic is
/// registered as a fallback here; calling the GoogleFonts factory once also
/// schedules the font for loading. Latin/Bengali typography is unaffected —
/// Roboto stays primary and the fallback only kicks in for glyphs it lacks.
final String? _notoArabic = GoogleFonts.notoSansArabic().fontFamily;
final List<String> _arabicFallback =
    _notoArabic != null ? [_notoArabic!] : const <String>[];

final poppinsRegular = GoogleFonts.roboto(
  fontWeight: FontWeight.w400,
  fontSize: Constants.fontSizeDefault,
).copyWith(fontFamilyFallback: _arabicFallback);

final poppinsMedium = GoogleFonts.roboto(
  fontWeight: FontWeight.w500,
  fontSize: Constants.fontSizeDefault,
).copyWith(fontFamilyFallback: _arabicFallback);

final poppinsBold = GoogleFonts.roboto(
  fontWeight: FontWeight.w700,
  fontSize: Constants.fontSizeDefault,
).copyWith(fontFamilyFallback: _arabicFallback);

final robotoBlack = GoogleFonts.roboto(
  fontWeight: FontWeight.w900,
  fontSize: Constants.fontSizeDefault,
).copyWith(fontFamilyFallback: _arabicFallback);
