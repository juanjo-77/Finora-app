import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppText {
  static TextStyle display = GoogleFonts.playfairDisplay(
    fontSize: 64, height: 1.0, letterSpacing: 0.6, color: AppColors.paperWhite,
  );
  static TextStyle heading = GoogleFonts.playfairDisplay(
    fontSize: 44, height: 1.1, letterSpacing: 0.4, color: AppColors.paperWhite,
  );
  static TextStyle subheading = GoogleFonts.inter(
    fontSize: 24, height: 1.0, letterSpacing: -0.31, fontWeight: FontWeight.w500,
    color: AppColors.paperWhite,
  );
  static TextStyle statNumber = GoogleFonts.playfairDisplay(
    fontSize: 40, fontWeight: FontWeight.w400, color: AppColors.paperWhite,
  );
  static TextStyle body = GoogleFonts.inter(
    fontSize: 16, height: 1.5, color: AppColors.fog,
  );
  static TextStyle bodyStrong = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.bone,
  );
  static TextStyle eyebrow = GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.26,
    color: AppColors.copper,
  );
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 13, color: AppColors.ash,
  );
}