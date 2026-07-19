import 'package:flutter/material.dart';
import 'package:chatrizz/app/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surfaceLightTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.purple,
        secondary: AppColors.purpleLight,
        surface: AppColors.surfaceLightTheme,
        onSurface: AppColors.textPrimaryLight,
        onBackground: AppColors.textPrimaryLight,
        error: AppColors.error,
        onError: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLightTheme,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLightTheme, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLightTheme),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLightTheme),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textTertiaryLight),
        labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.purple,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textPrimaryLight),
        displayMedium: TextStyle(color: AppColors.textPrimaryLight),
        displaySmall: TextStyle(color: AppColors.textPrimaryLight),
        headlineLarge: TextStyle(color: AppColors.textPrimaryLight),
        headlineMedium: TextStyle(color: AppColors.textPrimaryLight),
        headlineSmall: TextStyle(color: AppColors.textPrimaryLight),
        titleLarge: TextStyle(color: AppColors.textPrimaryLight),
        titleMedium: TextStyle(color: AppColors.textPrimaryLight),
        titleSmall: TextStyle(color: AppColors.textPrimaryLight),
        bodyLarge: TextStyle(color: AppColors.textPrimaryLight),
        bodyMedium: TextStyle(color: AppColors.textPrimaryLight),
        bodySmall: TextStyle(color: AppColors.textTertiaryLight),
        labelLarge: TextStyle(color: AppColors.textPrimaryLight),
        labelMedium: TextStyle(color: AppColors.textPrimaryLight),
        labelSmall: TextStyle(color: AppColors.textTertiaryLight),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLightTheme,
        selectedItemColor: AppColors.purple,
        unselectedItemColor: AppColors.textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLightTheme,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.purpleSurfaceLight,
        labelStyle: const TextStyle(color: AppColors.purple, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceCardLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimaryLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.purple,
        secondary: AppColors.purpleLight,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.purpleLight,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textPrimary),
        displayMedium: TextStyle(color: AppColors.textPrimary),
        displaySmall: TextStyle(color: AppColors.textPrimary),
        headlineLarge: TextStyle(color: AppColors.textPrimary),
        headlineMedium: TextStyle(color: AppColors.textPrimary),
        headlineSmall: TextStyle(color: AppColors.textPrimary),
        titleLarge: TextStyle(color: AppColors.textPrimary),
        titleMedium: TextStyle(color: AppColors.textPrimary),
        titleSmall: TextStyle(color: AppColors.textPrimary),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textTertiary),
        labelLarge: TextStyle(color: AppColors.textPrimary),
        labelMedium: TextStyle(color: AppColors.textPrimary),
        labelSmall: TextStyle(color: AppColors.textTertiary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.purple,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.purpleSurface,
        labelStyle: const TextStyle(color: AppColors.purpleLight, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
