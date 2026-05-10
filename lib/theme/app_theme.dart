import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand
  static const primaryBlue = Color(0xFF1652F0); // brand-600
  static const primaryPress = Color(0xFF0E3FC2); // brand-700
  static const primaryHover = Color(0xFF3B73FF); // brand-500
  static const primaryTint = Color(0xFFE6EEFF); // brand-100
  static const primaryFaint = Color(0xFFF2F6FF); // brand-050

  // Ink (text & UI — cool near-black with blue cast)
  static const heading = Color(0xFF0A1330); // ink-900
  static const ink700 = Color(0xFF2A335A);
  static const muted = Color(0xFF5B6386); // ink-500
  static const label = Color(0xFF858CAB); // ink-400
  static const border2 = Color(0xFFB6BACE); // ink-300
  static const border = Color(0xFFECEEF5); // ink-100 (divider)
  static const borderStrong = Color(0xFFD7DAE6); // ink-200
  static const surfaceMuted = Color(0xFFF5F6FA); // ink-050

  // Surface
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF8F9FC);

  // Semantic
  static const success = Color(0xFF16A34A);
  static const warn = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
}

ThemeData buildAppTheme() {
  final base = ThemeData.light();
  final baseText = base.textTheme;

  final textTheme = GoogleFonts.jetBrainsMonoTextTheme(baseText).copyWith(
    displayLarge: GoogleFonts.spaceGrotesk(textStyle: baseText.displayLarge),
    displayMedium: GoogleFonts.spaceGrotesk(textStyle: baseText.displayMedium),
    displaySmall: GoogleFonts.spaceGrotesk(textStyle: baseText.displaySmall),
    headlineLarge: GoogleFonts.spaceGrotesk(textStyle: baseText.headlineLarge),
    headlineMedium:
        GoogleFonts.spaceGrotesk(textStyle: baseText.headlineMedium),
    headlineSmall: GoogleFonts.spaceGrotesk(textStyle: baseText.headlineSmall),
    titleLarge: GoogleFonts.spaceGrotesk(textStyle: baseText.titleLarge),
  ).apply(
    bodyColor: AppColors.heading,
    displayColor: AppColors.heading,
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primaryBlue,
    primary: AppColors.primaryBlue,
    surface: AppColors.surface,
    onSurface: AppColors.heading,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColors.surface,
    canvasColor: AppColors.surface,
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.heading,
      surfaceTintColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.heading,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: AppColors.label),
      labelStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.jetBrainsMono(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.jetBrainsMono(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.heading,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.jetBrainsMono(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        textStyle: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.heading,
      ),
      contentTextStyle: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        color: AppColors.heading,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.heading,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primaryBlue : AppColors.muted,
        );
      }),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.muted,
      textColor: AppColors.heading,
    ),
    iconTheme: const IconThemeData(color: AppColors.heading),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.heading,
      contentTextStyle: GoogleFonts.jetBrainsMono(
        color: Colors.white,
        fontSize: 14,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.surface;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryBlue;
        return AppColors.border;
      }),
    ),
  );
}
