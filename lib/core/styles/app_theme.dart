import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Hanalei',
          color: AppColors.textPrimary,
          fontWeight: .w300,
          fontSize: 96,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Hanalei',
          color: AppColors.textPrimary,
          fontWeight: .w400,
          fontSize: 60,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Hanalei',
          color: AppColors.textPrimary,
          fontWeight: .w400,
          fontSize: 48,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Hanalei',
          color: AppColors.textPrimary,
          fontWeight: .w400,
          fontSize: 34,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Hanalei',
          fontWeight: .w600,
          color: AppColors.textPrimary,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Fredoka',
          color: AppColors.textPrimary,
          fontWeight: .w500,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Fredoka',
          color: AppColors.textPrimary,
          fontWeight: .w500,
          fontSize: 18,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Fredoka',
          color: AppColors.textPrimary,
          fontWeight: .w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Fredoka',
          color: AppColors.textSecondary,
          fontWeight: .w400,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Fredoka',
          color: AppColors.textSecondary,
          fontWeight: .w400,
          fontSize: 12,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: .w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
