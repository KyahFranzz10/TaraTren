import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/notification_service.dart';
import 'services/voice_service.dart';
import 'services/settings_service.dart';
import 'services/location_service.dart';
import 'services/background_tracking_service.dart';
import 'widgets/system_dynamic_island.dart';
import 'services/system_overlay_service.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize DotEnv and Supabase for the overlay process as well
  try {
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    debugPrint("Overlay Supabase init error: $e");
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        color: Colors.transparent, // Background of the overlay window
        child: const SystemDynamicIsland(),
      ),
    ),
  );
}

void main() async {
  // Essential for any platform-specific initialization
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize DotEnv and Supabase
  try {
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    debugPrint("Supabase successfully initialized.");
  } catch (e) {
    debugPrint("CRITICAL: Supabase initialization failed: $e");
  }

  // 2. Auxiliary Services (Sequential initialization)
  await _initServices();
  
  runApp(const TaraTrenApp());
}

Future<void> _initServices() async {
  try {
    // Initialize notification channel
    await NotificationService().init();
    
    // Load local settings and voice
    await VoiceService().init();
    await SettingsService().init();

    // Start background tracking service
    await BackgroundTrackingService.initializeService();

    // Start UI tracking
    await LocationService().init();
    
    // Request permissions
    await NotificationService().requestPermission();
    await SystemOverlayService().requestPermission();
    
  } catch (e) {
    debugPrint("Service initialization error: $e");
  }
}

class TaraTrenApp extends StatelessWidget {
  const TaraTrenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService().themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Tara Tren',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          // Light Theme (Clean, Corporate, Professional)
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D1B3E),
              primary: const Color(0xFF0D1B3E),
              secondary: const Color(0xFFE65100), // Vibrant Orange
              surface: Colors.white,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0D1B3E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          // Dark Theme (Neon, Midnight, High-Tech)
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF64B5F6), // Brighter seed for dark mode
              primary: const Color(0xFF90CAF9), // Lighter blue for dark mode
              secondary: Colors.orangeAccent,
              surface: const Color(0xFF121212),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0A0E17), // Deep Space Blue
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0D1B3E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
