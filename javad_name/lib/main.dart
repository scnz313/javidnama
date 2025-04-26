import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'constants.dart';
import 'screens/main_screen.dart';
import 'controllers/theme_controller.dart';
import 'screens/onboarding_screen.dart';
import 'utils/onboarding_util.dart';

// Only import web plugins when running on web
// This avoids the dart:ui_web errors on non-web platforms
import 'package:flutter_web_plugins/url_strategy.dart' if (dart.library.html) 'package:flutter_web_plugins/flutter_web_plugins.dart';

Future<void> main() async {
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      print(message);
    }
  };
  // Ensure Flutter bindings are initialized before using plugins
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Store Gemini API key in secure storage
  const storage = FlutterSecureStorage();
  await storage.write(key: 'GEMINI_API_KEY', value: 'AIzaSyCFdjGYZnRVzi0BoZNZyjxektA_9cfCAcM');
  
  // Only use web-specific URL strategy when on web platform
  if (kIsWeb) {
    // Configure URL strategy for web only
    usePathUrlStrategy();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showOnboarding = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadThemePreferences();
    final shouldShowOnboarding = await OnboardingUtil.shouldShowOnboarding();
    
    setState(() {
      _showOnboarding = shouldShowOnboarding;
      _isLoading = false;
    });
  }

  Future<void> _loadThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString('theme_preference') ?? 'light';
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
      final fontSize = prefs.getDouble('font_size_factor') ?? 1.0;
      setState(() {
        AppTheme.setTheme(themeType);
        AppTheme.setFontSize(fontSize);
      });
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }
  
  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeType>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, theme, child) {
        return MaterialApp(
          title: 'Javied Nama',
          theme: AppTheme.getTheme(),
          home: _isLoading
              ? const _LoadingScreen()
              : _showOnboarding
                  ? OnboardingScreen(onComplete: _onOnboardingComplete)
                  : const MainScreen(),
        );
      },
    );
  }
}

// Simple loading screen to show while checking onboarding status
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Just use an icon directly instead of trying to load a font file as an image
            const Icon(
              Icons.menu_book,
              size: 100,
              color: Color(0xFF614A19),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF614A19)),
            ),
          ],
        ),
      ),
    );
  }
}
