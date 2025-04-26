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

  static Future<void> setFontFamily(String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font_family_preference', fontFamily);
    AppTheme.setFontFamily(fontFamily);
  }

  static Future<void> loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme preference
    final themeName = prefs.getString('theme_preference');
    if (themeName != null) {
      ThemeType themeType;
      switch (themeName) {
        case 'dark':
          themeType = ThemeType.dark;
          break;
        case 'sepia':
          themeType = ThemeType.sepia;
          break;
        default:
          themeType = ThemeType.light;
      }
      AppTheme.setTheme(themeType);
    }
    
    // Load font size
    final fontSize = prefs.getDouble('font_size_factor');
    if (fontSize != null) {
      AppTheme.setFontSize(fontSize);
    }
    
    // Load font family
    final fontFamily = prefs.getString('font_family_preference');
    if (fontFamily != null && AppTheme.availableFonts.contains(fontFamily)) {
      AppTheme.setFontFamily(fontFamily);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
