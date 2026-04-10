import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'services/voice_service.dart';
import 'services/settings_service.dart';
import 'services/location_service.dart';
import 'services/background_tracking_service.dart';
import 'widgets/system_dynamic_island.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
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
  
  // 1. Force Firebase to initialize before ANYTHING else
  try {
    await Firebase.initializeApp();
    debugPrint("Firebase successfully initialized.");
  } catch (e) {
    debugPrint("CRITICAL: Firebase initialization failed: $e");
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
    
  } catch (e) {
    debugPrint("Service initialization error: $e");
  }
}

class TaraTrenApp extends StatelessWidget {
  const TaraTrenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Tara Tren',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D1B3E),
          primary: const Color(0xFF0D1B3E),
          secondary: Colors.orange,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1B3E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
