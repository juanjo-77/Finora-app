import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Unbounded para cifras y títulos; Instrument Sans para leer.
class AppText {
  static const tabular = [FontFeature.tabularFigures()];

  static TextStyle display = GoogleFonts.unbounded(
    fontSize: 40, height: 1.1, letterSpacing: -1.6, fontWeight: FontWeight.w700,
    color: AppColors.gold, fontFeatures: tabular,
  );
  static TextStyle heading = GoogleFonts.unbounded(
    fontSize: 24, height: 1.15, letterSpacing: -0.6, fontWeight: FontWeight.w500, color: AppColors.ivory,
  );
  static TextStyle subheading = GoogleFonts.unbounded(
    fontSize: 17, height: 1.2, letterSpacing: -0.4, fontWeight: FontWeight.w500, color: AppColors.ivory,
  );
  static TextStyle statNumber = GoogleFonts.unbounded(
    fontSize: 22, height: 1.1, letterSpacing: -0.5, fontWeight: FontWeight.w500,
    color: AppColors.ivory, fontFeatures: tabular,
  );
  static TextStyle amount = GoogleFonts.unbounded(
    fontSize: 14, height: 1.1, letterSpacing: -0.3, fontWeight: FontWeight.w500,
    color: AppColors.ivory, fontFeatures: tabular,
  );
  static TextStyle body = GoogleFonts.instrumentSans(
    fontSize: 15, height: 1.5, color: AppColors.sand,
  );
  static TextStyle bodyStrong = GoogleFonts.instrumentSans(
    fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ivory,
  );
  static TextStyle eyebrow = GoogleFonts.instrumentSans(
    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gold,
  );
  static TextStyle caption = GoogleFonts.instrumentSans(
    fontSize: 12.5, color: AppColors.dust,
  );
}
