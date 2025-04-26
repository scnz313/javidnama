import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);
    final themeData = AppTheme.buildThemeData(themeSettings);

    return MaterialApp(
      title: 'Javied Nama',
      theme: themeData,
      home: const MainScreen(),
    );
  }
}
