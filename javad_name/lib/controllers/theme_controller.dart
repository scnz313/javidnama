import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class ThemeController {
  static Future<void> setTheme(ThemeType themeType) async {
    final prefs = await SharedPreferences.getInstance();
    String themeName;
    switch (themeType) {
      case ThemeType.dark:
        themeName = 'dark';
        break;
      case ThemeType.sepia:
        themeName = 'sepia';
        break;
      default:
        themeName = 'light';
    }
    await prefs.setString('theme_preference', themeName);
    AppTheme.setTheme(themeType);
  }

  static Future<void> setFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size_factor', fontSize);
    AppTheme.setFontSize(fontSize);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
