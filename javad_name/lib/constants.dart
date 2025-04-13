import 'package:flutter/material.dart';

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

  // Active theme properties (default to light)
  static Color get background => _getColor(
    ThemeType.light,
    lightBackground,
    darkBackground,
    sepiaBackground,
  );
  static Color get surface =>
      _getColor(ThemeType.light, lightSurface, darkSurface, sepiaSurface);
  static Color get primary =>
      _getColor(ThemeType.light, lightPrimary, darkPrimary, sepiaPrimary);
  static Color get primaryLight => _getColor(
    ThemeType.light,
    lightPrimaryLight,
    darkPrimaryLight,
    sepiaPrimaryLight,
  );
  static Color get accent =>
      _getColor(ThemeType.light, lightAccent, darkAccent, sepiaAccent);
  static Color get textDark =>
      _getColor(ThemeType.light, lightTextDark, darkTextDark, sepiaTextDark);
  static Color get textMedium => _getColor(
    ThemeType.light,
    lightTextMedium,
    darkTextMedium,
    sepiaTextMedium,
  );
  static Color get textLight =>
      _getColor(ThemeType.light, lightTextLight, darkTextLight, sepiaTextLight);
  static Color get divider =>
      _getColor(ThemeType.light, lightDivider, darkDivider, sepiaDivider);

  // Helper method to get color based on theme type
  static Color _getColor(
    ThemeType themeType,
    Color light,
    Color dark,
    Color sepia,
  ) {
    switch (AppTheme.currentTheme) {
      case ThemeType.light:
        return light;
      case ThemeType.dark:
        return dark;
      case ThemeType.sepia:
        return sepia;
    }
  }
}

enum ThemeType { light, dark, sepia }

class AppTheme {
  // Current theme state
  static ThemeType currentTheme = ThemeType.light;
  static double _fontSize = 1.0; // Scale factor for text size

  // Get font scale factor
  static double get fontSize => _fontSize;

  // Set font scale factor
  static void setFontSize(double size) {
    _fontSize = size;
  }

  // Set current theme
  static void setTheme(ThemeType theme) {
    currentTheme = theme;
  }

  // Get theme data based on current theme type
  static ThemeData getTheme() {
    switch (currentTheme) {
      case ThemeType.light:
        return _getLightTheme();
      case ThemeType.dark:
        return _getDarkTheme();
      case ThemeType.sepia:
        return _getSepiaTheme();
    }
  }

  // Light theme configuration
  static ThemeData _getLightTheme() => _buildTheme(
    AppColors.lightBackground,
    AppColors.lightSurface,
    AppColors.lightPrimary,
    AppColors.lightPrimaryLight,
    AppColors.lightAccent,
    AppColors.lightTextDark,
    AppColors.lightTextMedium,
    AppColors.lightTextLight,
    AppColors.lightDivider,
    Brightness.light,
  );

  // Dark theme configuration
  static ThemeData _getDarkTheme() => _buildTheme(
    AppColors.darkBackground,
    AppColors.darkSurface,
    AppColors.darkPrimary,
    AppColors.darkPrimaryLight,
    AppColors.darkAccent,
    AppColors.darkTextDark,
    AppColors.darkTextMedium,
    AppColors.darkTextLight,
    AppColors.darkDivider,
    Brightness.dark,
  );

  // Sepia theme configuration
  static ThemeData _getSepiaTheme() => _buildTheme(
    AppColors.sepiaBackground,
    AppColors.sepiaSurface,
    AppColors.sepiaPrimary,
    AppColors.sepiaPrimaryLight,
    AppColors.sepiaAccent,
    AppColors.sepiaTextDark,
    AppColors.sepiaTextMedium,
    AppColors.sepiaTextLight,
    AppColors.sepiaDivider,
    Brightness.light,
  );

  // Common theme builder
  static ThemeData _buildTheme(
    Color background,
    Color surface,
    Color primary,
    Color primaryLight,
    Color accent,
    Color textDark,
    Color textMedium,
    Color textLight,
    Color divider,
    Brightness brightness,
  ) {
    return ThemeData(
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
          fontFamily: 'Jameelnoori',
          color: textDark,
          fontSize: 20 * _fontSize,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: primary),
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
          fontFamily: 'Jameelnoori',
          color: textDark,
          fontSize: 24 * _fontSize,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Jameelnoori',
          color: textDark,
          fontSize: 22 * _fontSize,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Jameelnoori',
          color: textDark,
          fontSize: 20 * _fontSize,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Jameelnoori',
          color: textDark,
          fontSize: 18 * _fontSize,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Jameelnoori',
          color: textMedium,
          fontSize: 18 * _fontSize,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Jameelnoori',
          color: textMedium,
          fontSize: 16 * _fontSize,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Jameelnoori',
          color: textLight,
          fontSize: 14 * _fontSize,
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

  // Original theme getter maintained for compatibility
  static ThemeData get theme => getTheme();
}
