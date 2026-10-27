import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  /// Curva firma: entra rápido y aterriza suave.
  static const ease = Cubic(0.2, 0.9, 0.25, 1);

  static ThemeData get dark {
    final radio14 = BorderRadius.circular(14);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.black,
      textTheme: GoogleFonts.instrumentSansTextTheme(ThemeData.dark().textTheme)
          .apply(bodyColor: AppColors.ivory, displayColor: AppColors.ivory),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        onPrimary: Colors.black,
        secondary: AppColors.gold,
        surface: AppColors.vault,
        onSurface: AppColors.ivory,
        error: AppColors.ember,
      ),
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        color: AppColors.vault,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.seam),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldHi,
          side: const BorderSide(color: AppColors.bronze),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.gold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.vault,
        hintStyle: AppText.body.copyWith(color: AppColors.dust),
        labelStyle: AppText.body,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: radio14, borderSide: const BorderSide(color: AppColors.seam)),
        enabledBorder: OutlineInputBorder(borderRadius: radio14, borderSide: const BorderSide(color: AppColors.seam)),
        focusedBorder: OutlineInputBorder(borderRadius: radio14, borderSide: const BorderSide(color: AppColors.gold)),
        errorBorder: OutlineInputBorder(borderRadius: radio14, borderSide: const BorderSide(color: AppColors.ember)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: radio14, borderSide: const BorderSide(color: AppColors.ember)),
        errorStyle: AppText.caption.copyWith(color: AppColors.ember),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ivory,
        titleTextStyle: AppText.subheading,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0D0B08),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.seam,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          side: BorderSide(color: AppColors.bronze),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.vault,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppText.subheading,
        contentTextStyle: AppText.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.seam),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.vault2,
        contentTextStyle: AppText.body.copyWith(color: AppColors.ivory, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.seam),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: AppColors.vault2,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: CircleBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.black : AppColors.sand),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.gold : AppColors.vault2),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.seam),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF1A1712), thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.vault2,
        selectedColor: AppColors.vault2,
        checkmarkColor: AppColors.goldHi,
        labelStyle: AppText.bodyStrong.copyWith(fontSize: 13, color: AppColors.sand),
        secondaryLabelStyle: AppText.bodyStrong.copyWith(fontSize: 13, color: AppColors.ivory),
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(color: s.contains(WidgetState.selected) ? AppColors.gold : AppColors.seam),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
