import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_border_radius.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.brand,
          onPrimary: AppColors.white,
          secondary: AppColors.brandLight,
          onSecondary: AppColors.brand,
          error: AppColors.error,
          surface: AppColors.surfaceL2,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: AppTypography.h4.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceL2,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.brand, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
          labelStyle: AppTypography.body.copyWith(color: AppColors.textPrimary),
          errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.display,
          headlineLarge: AppTypography.h1,
          headlineMedium: AppTypography.h2,
          headlineSmall: AppTypography.h3,
          titleLarge: AppTypography.h4,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.body,
          bodySmall: AppTypography.bodySmall,
          labelLarge: AppTypography.label,
          labelSmall: AppTypography.caption,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.brand,
          unselectedItemColor: AppColors.textTertiary,
          elevation: 0,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.brandDarkMode,
          onPrimary: AppColors.white,
          secondary: AppColors.brandLightDarkMode,
          onSecondary: AppColors.brandDarkMode,
          error: AppColors.error,
          surface: AppColors.surfaceL1Dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: AppTypography.h4.copyWith(
            color: AppColors.textPrimaryDark,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceL1Dark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.borderDark),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceL2Dark,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide:
                const BorderSide(color: AppColors.brandDarkMode, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle:
              AppTypography.body.copyWith(color: AppColors.textSecondary),
          labelStyle:
              AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
          errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.display.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          headlineLarge: AppTypography.h1.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          headlineMedium: AppTypography.h2.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          headlineSmall: AppTypography.h3.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          titleLarge: AppTypography.h4.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          bodyLarge: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          bodyMedium: AppTypography.body.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          bodySmall: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          labelLarge: AppTypography.label.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          labelSmall: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderDark,
          thickness: 1,
          space: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceL1Dark,
          selectedItemColor: AppColors.brandDarkMode,
          unselectedItemColor: AppColors.textTertiary,
          elevation: 0,
        ),
      );
}