import 'package:flutter/material.dart';
import 'controllers/theme_controller.dart'; // Import ThemeSettings

class AppColors {
  // Light theme - modern, minimalistic color palette
  static const lightBackground = Color(0xFFF8F9FA);
  static const lightSurface = Colors.white;
  static const lightPrimary = Color(0xFF614A19); // Deep gold
  static const lightPrimaryLight = Color(0xFFD4B56B); // Light gold
  static const lightAccent = Color(0xFFAF894F); // Medium gold
  static const lightTextDark = Color(0xFF2D2A26); // Near black
  static const lightTextMedium = Color(0xFF515151); // Dark gray
  static const lightTextLight = Color(0xFF757575); // Medium gray
  static const lightDivider = Color(0xFFE0E0E0); // Light gray

  // Dark theme colors
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkPrimary = Color(0xFFD4B56B); // Gold accent
  static const darkPrimaryLight = Color(0xFFAF894F);
  static const darkAccent = Color(0xFFBB9654);
  static const darkTextDark = Color(0xFFFFFFFF);
  static const darkTextMedium = Color(0xFFE0E0E0);
  static const darkTextLight = Color(0xFFACACAC);
  static const darkDivider = Color(0xFF323232);

  // Sepia theme colors
  static const sepiaBackground = Color(0xFFF8ECD4);
  static const sepiaSurface = Color(0xFFFFF8EC);
  static const sepiaPrimary = Color(0xFF8B5A2B);
  static const sepiaPrimaryLight = Color(0xFFBF8F5F);
  static const sepiaAccent = Color(0xFFA67C52);
  static const sepiaTextDark = Color(0xFF442C14);
  static const sepiaTextMedium = Color(0xFF614A19);
  static const sepiaTextLight = Color(0xFF7F6542);
  static const sepiaDivider = Color(0xFFE6D5B8);
}

enum ThemeType { light, dark, sepia }

class AppTheme {
  static const List<String> availableFonts = ['Jameelnoori', 'NotoNastaliqUrdu', 'MehrNastaliq', 'Amiri', 'Lora', 'OpenSans', 'Roboto'];

  static ThemeData buildThemeData(ThemeSettings settings) {
    switch (settings.themeType) {
      case ThemeType.light:
        return _getLightTheme(settings);
      case ThemeType.dark:
        return _getDarkTheme(settings);
      case ThemeType.sepia:
        return _getSepiaTheme(settings);
    }
  }

  static ThemeData _getLightTheme(ThemeSettings settings) {
    return _buildTheme(
      settings: settings,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
      primary: AppColors.lightPrimary,
      primaryLight: AppColors.lightPrimaryLight,
      accent: AppColors.lightAccent,
      textDark: AppColors.lightTextDark,
      textMedium: AppColors.lightTextMedium,
      textLight: AppColors.lightTextLight,
      divider: AppColors.lightDivider,
      brightness: Brightness.light,
    );
  }

  static ThemeData _getDarkTheme(ThemeSettings settings) {
    return _buildTheme(
      settings: settings,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      primary: AppColors.darkPrimary,
      primaryLight: AppColors.darkPrimaryLight,
      accent: AppColors.darkAccent,
      textDark: AppColors.darkTextDark,
      textMedium: AppColors.darkTextMedium,
      textLight: AppColors.darkTextLight,
      divider: AppColors.darkDivider,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _getSepiaTheme(ThemeSettings settings) {
    return _buildTheme(
      settings: settings,
      background: AppColors.sepiaBackground,
      surface: AppColors.sepiaSurface,
      primary: AppColors.sepiaPrimary,
      primaryLight: AppColors.sepiaPrimaryLight,
      accent: AppColors.sepiaAccent,
      textDark: AppColors.sepiaTextDark,
      textMedium: AppColors.sepiaTextMedium,
      textLight: AppColors.sepiaTextLight,
      divider: AppColors.sepiaDivider,
      brightness: Brightness.light,
    );
  }

  static ThemeData _buildTheme({
    required ThemeSettings settings,
    required Color background,
    required Color surface,
    required Color primary,
    required Color primaryLight,
    required Color accent,
    required Color textDark,
    required Color textMedium,
    required Color textLight,
    required Color divider,
    required Brightness brightness,
  }) {
    final double uiFontScale = settings.fontSizeFactor;
    final String currentFontFamily = settings.fontFamily;

    return ThemeData(
      fontFamily: currentFontFamily,
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: brightness == Brightness.light ? Colors.white : Colors.black,
        secondary: accent,
        onSecondary:
            brightness == Brightness.light ? Colors.white : Colors.black,
        error: Colors.red,
        onError: Colors.white,
        background: background,
        onBackground: textDark,
        surface: surface,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: currentFontFamily,
          color: textDark,
          fontSize: 20 * uiFontScale,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 3,
        indicatorColor: primary.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(
              color: primary,
              fontFamily: currentFontFamily,
              fontSize: 12 * uiFontScale,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: textMedium,
            fontFamily: currentFontFamily,
            fontSize: 12 * uiFontScale,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: primary);
          }
          return IconThemeData(color: textMedium);
        }),
        shadowColor: primary.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        height: 64,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 2,
        shadowColor: primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: currentFontFamily,
          color: textDark,
          fontSize: 24 * uiFontScale,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          fontFamily: currentFontFamily,
          color: textDark,
          fontSize: 22 * uiFontScale,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontFamily: currentFontFamily,
          color: textDark,
          fontSize: 20 * uiFontScale,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontFamily: currentFontFamily,
          color: textDark,
          fontSize: 18 * uiFontScale,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontFamily: currentFontFamily,
          color: textMedium,
          fontSize: 18 * uiFontScale,
        ),
        bodyMedium: TextStyle(
          fontFamily: currentFontFamily,
          color: textMedium,
          fontSize: 16 * uiFontScale,
        ),
        bodySmall: TextStyle(
          fontFamily: currentFontFamily,
          color: textLight,
          fontSize: 14 * uiFontScale,
        ),
      ),
      iconTheme: IconThemeData(color: primary, size: 24),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 24),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor:
              brightness == Brightness.light ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return brightness == Brightness.light
              ? Colors.grey.shade400
              : Colors.grey.shade700;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primary.withOpacity(0.5);
          }
          return brightness == Brightness.light
              ? Colors.grey.shade300
              : Colors.grey.shade800;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        inactiveTrackColor: primary.withOpacity(0.2),
      ),
    );
  }
}
