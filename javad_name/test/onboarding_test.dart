import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/utils/onboarding_util.dart';

void main() {
  group('Onboarding Utility Tests', () {
    setUp(() async {
      // Set up a mock for SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    test('hasSeenOnboarding should return false initially', () async {
      // The mock starts with no value, so it should return false
      expect(await OnboardingUtil.hasSeenOnboarding(), false);
    });

    test('shouldShowOnboarding should return true initially', () async {
      // The mock starts with no value, so it should show onboarding
      expect(await OnboardingUtil.shouldShowOnboarding(), true);
    });

    test('resetOnboardingStatus should set hasSeenOnboarding to false', () async {
      // First, manually set it to true
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);
      
      // Verify it was set
      expect(await OnboardingUtil.hasSeenOnboarding(), true);
      
      // Now reset it
      await OnboardingUtil.resetOnboardingStatus();
      
      // Verify it's back to false
      expect(await OnboardingUtil.hasSeenOnboarding(), false);
    });
  });
}
