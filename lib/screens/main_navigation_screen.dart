import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'news_feed_screen.dart';
import '../widgets/app_drawer.dart';
import '../services/navigation_controller.dart';
import '../services/offline_storage_service.dart';
import '../models/scraped_alert.dart';
import '../services/notification_service.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = NavigationController().selectedIndex.value;
  Timer? _alertTimer;
  ScrapedAlert? _currentCriticalAlert;
  String? _lastNotifiedAlertId;

  @override
  void initState() {
    super.initState();
    NavigationController().selectedIndex.addListener(_onNavigationChanged);
    _startAlertMonitor();
  }

  void _startAlertMonitor() {
     _checkAlerts(); // Check immediately
     _alertTimer = Timer.periodic(const Duration(seconds: 60), (timer) => _checkAlerts());
  }

  Future<void> _checkAlerts() async {
    final alerts = await OfflineStorageService().getLatestAlerts(limit: 5);
    ScrapedAlert? newCritical;
    for (var a in alerts) {
      final m = a.message.toLowerCase();
      if (m.contains("interruption") || m.contains("incident") || m.contains("suspended") || m.contains("provisional") || m.contains("limited")) {
        newCritical = a;
        break;
      }
    }
    if (mounted) {
      setState(() {
        _currentCriticalAlert = newCritical;
      });
      if (newCritical != null) {
        final String alertKey = "${newCritical.line}_${newCritical.timestamp.toIso8601String()}";
        if (alertKey != _lastNotifiedAlertId) {
          _lastNotifiedAlertId = alertKey;
          _triggerAlertEffects(newCritical);
        }
      }
    }
  }

  void _triggerAlertEffects(ScrapedAlert alert) {
    HapticFeedback.vibrate();
    NotificationService().showNotification(
      id: 888, 
      title: "🚨 BREAKING: ${alert.line} Issue", 
      body: alert.message.length > 100 ? alert.message.substring(0, 100) + "..." : alert.message
    );
  }

  @override
  void dispose() {
    NavigationController().selectedIndex.removeListener(_onNavigationChanged);
    _alertTimer?.cancel();
    super.dispose();
  }

  void _onNavigationChanged() {
    if (mounted) {
      setState(() {
        _selectedIndex = NavigationController().selectedIndex.value;
      });
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const NewsFeedScreen(),
  ];

  void _onItemTapped(int index) {
    NavigationController().setTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tara ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const Text('Tren', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.orange)),
          ],
        ),
        actions: [
          // Global User/Profile Icon Section
          StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              final user = snapshot.data?.session?.user ?? Supabase.instance.client.auth.currentUser;
              final photoUrl = user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'];
              final bool isGuest = user == null || user.isAnonymous;

              return IconButton(
                onPressed: () {
                  if (user != null && !user.isAnonymous) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                  }
                },
                icon: photoUrl != null 
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(photoUrl),
                      ),
                    )
                  : Icon(
                      isGuest ? Icons.account_circle_outlined : Icons.account_circle,
                      color: isDark ? Colors.orange : const Color(0xFF0D1B3E),
                      size: 28,
                    ),
                tooltip: isGuest ? 'Sign In' : 'Account',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildGlobalBreakingNewsTicker(),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0D1B3E),
          elevation: 0,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'News',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.white60,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildGlobalBreakingNewsTicker() {
    final alert = _currentCriticalAlert;
    final String displayMessage = alert != null 
      ? "${alert.line}: ${alert.message.length > 65 ? alert.message.substring(0, 65) + '...' : alert.message}"
      : ""; 
    final Color barColor = alert != null 
      ? (alert.message.toLowerCase().contains("interruption") ? Colors.red.shade900 : Colors.orange.shade800)
      : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutSine,
      width: double.infinity,
      height: alert != null ? 36 : 0, 
      color: barColor,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: alert != null ? 1.0 : 0.0,
        child: alert != null ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text("🚨 BREAKING", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.white)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    displayMessage,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ) : const SizedBox.shrink(),
      ),
    );
  }
}
