import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart'; // For ThemeType and AppTheme.availableFonts
import 'package:flutter/material.dart'; // For ThemeType definition access

// Default values
const _defaultTheme = ThemeType.light;
const _defaultFontSizeFactor = 1.0;
const _defaultFontFamily = 'Jameelnoori';

// Preference Keys
const _themePrefKey = 'theme_preference';
const _fontSizePrefKey = 'font_size_factor';
const _fontFamilyPrefKey = 'font_family_preference';

// 1. Define the immutable state class
@immutable
class ThemeSettings {
  final ThemeType themeType;
  final double fontSizeFactor;
  final String fontFamily;

  const ThemeSettings({
    required this.themeType,
    required this.fontSizeFactor,
    required this.fontFamily,
  });

  // Method to create a copy with updated values
  ThemeSettings copyWith({
    ThemeType? themeType,
    double? fontSizeFactor,
    String? fontFamily,
  }) {
    return ThemeSettings(
      themeType: themeType ?? this.themeType,
      fontSizeFactor: fontSizeFactor ?? this.fontSizeFactor,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeSettings &&
          runtimeType == other.runtimeType &&
          themeType == other.themeType &&
          fontSizeFactor == other.fontSizeFactor &&
          fontFamily == other.fontFamily;

  @override
  int get hashCode => themeType.hashCode ^ fontSizeFactor.hashCode ^ fontFamily.hashCode;
}

// 2. Define the StateNotifier
class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  ThemeSettingsNotifier() : super(const ThemeSettings(
          themeType: _defaultTheme,
          fontSizeFactor: _defaultFontSizeFactor,
          fontFamily: _defaultFontFamily,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Theme
      final themeName = prefs.getString(_themePrefKey) ?? _defaultTheme.name;
      final themeType = ThemeType.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => _defaultTheme,
      );

      // Load Font Size
      final fontSizeFactor = prefs.getDouble(_fontSizePrefKey) ?? _defaultFontSizeFactor;

      // Load Font Family
      final fontFamily = prefs.getString(_fontFamilyPrefKey) ?? _defaultFontFamily;
      final validFontFamily = AppTheme.availableFonts.contains(fontFamily)
          ? fontFamily
          : _defaultFontFamily;

      state = ThemeSettings(
        themeType: themeType,
        fontSizeFactor: fontSizeFactor,
        fontFamily: validFontFamily,
      );
    } catch (e) {
      debugPrint('Error loading theme settings: $e');
      // Keep default state if loading fails
    }
  }

  Future<void> setTheme(ThemeType themeType) async {
    if (state.themeType == themeType) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, themeType.name);
      state = state.copyWith(themeType: themeType);
    } catch (e) {
      debugPrint('Error saving theme setting: $e');
    }
  }

  Future<void> setFontSizeFactor(double fontSizeFactor) async {
    // Add reasonable bounds if desired, e.g., clamp between 0.8 and 2.0
    // final clampedSize = fontSizeFactor.clamp(0.8, 2.0);
    if (state.fontSizeFactor == fontSizeFactor) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizePrefKey, fontSizeFactor);
      state = state.copyWith(fontSizeFactor: fontSizeFactor);
    } catch (e) {
      debugPrint('Error saving font size setting: $e');
    }
  }

  Future<void> setFontFamily(String fontFamily) async {
    if (!AppTheme.availableFonts.contains(fontFamily) || state.fontFamily == fontFamily) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontFamilyPrefKey, fontFamily);
      state = state.copyWith(fontFamily: fontFamily);
    } catch (e) {
      debugPrint('Error saving font family setting: $e');
    }
  }
}

// 3. Define the Provider
final themeSettingsProvider = StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  return ThemeSettingsNotifier();
});

// Keep the extension if it's used elsewhere, otherwise it can be removed.
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
