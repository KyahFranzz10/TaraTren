import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/settings_service.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedType = 'normal';
  bool _locationGranted = false;
  bool _notificationGranted = false;
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    setState(() {
      _locationGranted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    });
  }

  Future<void> _requestLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    setState(() {
      _locationGranted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    });
  }

  Future<void> _requestNotification() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // For Android 13+
    final bool? granted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    setState(() {
      _notificationGranted = granted ?? true; // Default to true if not on Android 13+ or already managed
    });
  }

  void _finishOnboarding() async {
    await _settings.setUserType(_selectedType);
    await _settings.setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B3E),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Personalize Your Ride",
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Tell us a bit about yourself to get accurate fare estimates and real-time updates.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 48),
                
                const Text("User Type", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTypeCard("Single Journey", "Standard full fare for occasional riders.", "normal", Icons.person_outline),
                const SizedBox(height: 12),
                _buildTypeCard("Beep Card User", "Stored Value discount (up to 20% off) applied.", "beep", Icons.credit_card),
                const SizedBox(height: 12),
                _buildTypeCard("White Beep Card", "50% Savings for Seniors, Students, and PWDs.", "white_beep", Icons.badge_outlined),
                
                const SizedBox(height: 48),
                
                const Text("Permissions Required", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPermissionTile(
                  title: "Location Services",
                  subtitle: "Required for nearest station alerts and tracking.",
                  isGranted: _locationGranted,
                  onTap: _requestLocation,
                  icon: Icons.my_location,
                ),
                const SizedBox(height: 12),
                _buildPermissionTile(
                  title: "Notifications",
                  subtitle: "Get arrival alerts even when the app is closed.",
                  isGranted: _notificationGranted,
                  onTap: _requestNotification,
                  icon: Icons.notifications_active,
                ),
                
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: (_locationGranted && _notificationGranted) ? _finishOnboarding : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D1B3E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
                      disabledForegroundColor: Colors.white24,
                    ),
                    child: const Text("Start Exploring", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(String label, String sub, String type, IconData icon) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile({required String title, required String subtitle, required bool isGranted, required VoidCallback onTap, required IconData icon}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: isGranted ? Colors.greenAccent : Colors.white70),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: ElevatedButton(
        onPressed: isGranted ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isGranted ? Colors.white10 : Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(isGranted ? "Granted" : "Allow"),
      ),
    );
  }
}
