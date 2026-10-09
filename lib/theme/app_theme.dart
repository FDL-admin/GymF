import 'package:flutter/material.dart';

import 'colors.dart';
import 'radii.dart';

abstract final class AppFonts {
  static const title = 'Rajdhani';
  static const body = 'Inter';
}

const List<FontFeature> _tabularFigures = [FontFeature.tabularFigures()];

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.dark(
    primary: AppColors.accentPrimary,
    onPrimary: AppColors.background,
    secondary: AppColors.accentSecondary,
    onSecondary: AppColors.text,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.danger,
    onError: AppColors.text,
    outline: AppColors.border,
  );

  final textTheme = const TextTheme(
    displayLarge: TextStyle(
      fontFamily: AppFonts.title,
      fontWeight: FontWeight.w700,
      fontSize: 40,
      color: AppColors.text,
    ),
    headlineLarge: TextStyle(
      fontFamily: AppFonts.title,
      fontWeight: FontWeight.w700,
      fontSize: 32,
      color: AppColors.text,
    ),
    headlineMedium: TextStyle(
      fontFamily: AppFonts.title,
      fontWeight: FontWeight.w700,
      fontSize: 26,
      color: AppColors.text,
    ),
    titleLarge: TextStyle(
      fontFamily: AppFonts.title,
      fontWeight: FontWeight.w600,
      fontSize: 20,
      letterSpacing: 1.5,
      color: AppColors.text,
    ),
    titleMedium: TextStyle(
      fontFamily: AppFonts.title,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      letterSpacing: 1,
      color: AppColors.text,
    ),
    bodyLarge: TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w400,
      fontSize: 16,
      color: AppColors.text,
    ),
    bodyMedium: TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: AppColors.text,
    ),
    bodySmall: TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w400,
      fontSize: 12,
      color: AppColors.textMuted,
    ),
    labelLarge: TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      letterSpacing: 0.5,
      color: AppColors.text,
    ),
    labelMedium: TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w500,
      fontSize: 12,
      color: AppColors.textMuted,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    fontFamily: AppFonts.body,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.title,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        letterSpacing: 1.5,
        color: AppColors.text,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accentPrimary,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontFamily: AppFonts.body, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontFamily: AppFonts.body, fontSize: 11),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x992E6BFF),
      thickness: 1,
      space: 1,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.accentPrimary,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.accentPrimary,
      dividerColor: AppColors.border,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.all),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: AppRadii.all),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.all,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.all,
        borderSide: BorderSide(color: AppColors.accentPrimary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadii.all,
        borderSide: BorderSide(color: AppColors.danger),
      ),
    ),
  );
}

abstract final class AppTextStyles {
  static const TextStyle digits = TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabularFigures,
    color: AppColors.text,
  );
}
