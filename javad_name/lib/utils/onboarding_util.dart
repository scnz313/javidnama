import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingUtil {
  // Key for storing the onboarding status in SharedPreferences
  static const String _hasSeenOnboardingKey = 'hasSeenOnboarding';

  // Check if the user has completed the onboarding
  static Future<bool> hasSeenOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  // Reset the onboarding status (useful for testing)
  static Future<void> resetOnboardingStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, false);
  }

  // Helper to show the onboarding screen if needed
  static Future<bool> shouldShowOnboarding() async {
    return !(await hasSeenOnboarding());
  }
}
