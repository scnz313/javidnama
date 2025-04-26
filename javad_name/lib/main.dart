import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'constants.dart';
import 'screens/main_screen.dart';
import 'controllers/theme_controller.dart';

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
  
  // Only use web-specific URL strategy when on web platform
  if (kIsWeb) {
    // Configure URL strategy for web only
    usePathUrlStrategy();
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _loadThemePreferences();
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeType>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, theme, child) {
        return MaterialApp(
          title: 'Javied Nama',
          theme: AppTheme.getTheme(),
          home: const MainScreen(),
        );
      },
    );
  }
}
