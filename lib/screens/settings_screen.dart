import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import '../services/settings_service.dart';
import '../services/location_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'legal_info_screen.dart';
import 'about_developer_screen.dart';
import '../services/system_overlay_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _voiceEnabled;
  late bool _offlineMode;
  late bool _powerSaving;
  late String _voiceLanguage;
  late String _voicePack;
  late String _userType;
  late ThemeMode _themeMode;
  final AuthService _auth = AuthService();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _voiceEnabled = SettingsService().isVoiceEnabled;
    _offlineMode = SettingsService().isOfflineMode;
    _powerSaving = SettingsService().isPowerSavingMode;
    _voiceLanguage = SettingsService().voiceLanguage;
    _voicePack = SettingsService().voicePack;
    _userType = SettingsService().userType;
    _themeMode = SettingsService().themeMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Notifications', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Voice Announcements'),
            subtitle: const Text('Speak station arrivals and alerts'),
            secondary: Icon(Icons.record_voice_over, color: Theme.of(context).colorScheme.primary),
            value: _voiceEnabled,
            onChanged: (value) async {
              setState(() => _voiceEnabled = value);
              await SettingsService().setVoiceEnabled(value);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Voice announcements ${value ? 'enabled' : 'disabled'}')),
                );
              }
            },
          ),
          if (_voiceEnabled)
            ListTile(
              title: const Text('Announcement Language'),
              leading: Icon(Icons.translate, color: Theme.of(context).colorScheme.primary),
              trailing: DropdownButton<String>(
                value: _voiceLanguage,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'english', child: Text('English')),
                  DropdownMenuItem(value: 'tagalog', child: Text('Tagalog')),
                  DropdownMenuItem(value: 'both', child: Text('Both')),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    setState(() => _voiceLanguage = value);
                    await SettingsService().setVoiceLanguage(value);
                  }
                },
              ),
            ),
          if (_voiceEnabled)
            ListTile(
              title: const Text('Voice Pack Style'),
              subtitle: const Text('Personality of the announcements'),
              leading: Icon(Icons.style, color: Theme.of(context).colorScheme.primary),
              trailing: DropdownButton<String>(
                value: _voicePack,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'professional', child: Text('Professional')),
                  DropdownMenuItem(value: 'casual', child: Text('Casual')),
                  DropdownMenuItem(value: 'conyo', child: Text('Taglish / Conyo')),
                  DropdownMenuItem(value: 'francis', child: Text('Francis (Personalized)')),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    setState(() => _voicePack = value);
                    await SettingsService().setVoicePack(value);
                  }
                },
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Appearance', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _themeCard(ThemeMode.light, Icons.light_mode, "Light"),
                const SizedBox(width: 12),
                _themeCard(ThemeMode.dark, Icons.dark_mode, "Dark"),
                const SizedBox(width: 12),
                _themeCard(ThemeMode.system, Icons.brightness_auto, "System"),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Data & Connectivity', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Offline Mode'),
            subtitle: const Text('Save data and battery. Station alerts and voice announcements still work via GPS.'),
            secondary: Icon(Icons.signal_wifi_off, color: Theme.of(context).colorScheme.primary),
            value: _offlineMode,
            onChanged: (value) async {
              setState(() => _offlineMode = value);
              await SettingsService().setOfflineMode(value);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Fare Profile', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('Travel Card Type'),
            subtitle: Text(_userType == 'normal' ? 'Single Journey (Full Fare)' : 
                           _userType == 'beep' ? 'Beep Card (Standard Discount)' : 
                           _userType == 'senior' ? 'Senior Citizen (50% Off)' : 'Student (50% Off)'),
            leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () {
               _showUserTypeDialog();
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Live Tracking & Overlays', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          FutureBuilder<bool>(
            future: FlutterOverlayWindow.isPermissionGranted(),
            builder: (context, snapshot) {
              final permissionGranted = snapshot.data ?? false;
              final bool isEnabled = SettingsService().isSystemIslandEnabled;

              return Column(
                children: [
                   SwitchListTile(
                    title: const Text('System Dynamic Island'),
                    subtitle: Text(!permissionGranted 
                      ? 'Tap to grant overlay permission' 
                      : (isEnabled ? 'Floating pill active' : 'Floating pill disabled')),
                    secondary: Icon(Icons.layers, color: Theme.of(context).colorScheme.primary),
                    value: isEnabled && permissionGranted,
                    onChanged: (value) async {
                      if (value) {
                        if (!permissionGranted) {
                          await FlutterOverlayWindow.requestPermission();
                        } else {
                          await SettingsService().setSystemIslandEnabled(true);
                          setState(() {});
                        }
                      } else {
                        await SettingsService().setSystemIslandEnabled(false);
                        await SystemOverlayService().hide();
                        setState(() {});
                      }
                    },
                  ),
                  if (permissionGranted && isEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Island Management", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text("Manually toggle the floating journey pill", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final svc = SystemOverlayService();
                                final bool active = await svc.isActive();
                                if (active) {
                                  LocationService().manuallyOpenedIsland.value = false;
                                  await svc.hide();
                                } else {
                                  LocationService().manuallyOpenedIsland.value = true;
                                  // Show base standby state
                                  await svc.show(
                                    nextStation: 'Search...',
                                    line: 'LRT1',
                                    speed: 0,
                                    isArrivalAlert: false,
                                    bodyText: 'Waiting for train detection...',
                                    prevStation: '--',
                                    currentStation: 'STANDBY',
                                    statusLabel: 'SEARCHING',
                                    distance: 0.0,
                                    pace: 'SCAN',
                                    isSouthbound: true,
                                  );
                                }
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text("TOGGLE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Battery & Optimization', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Power Saving Mode'),
            subtitle: const Text('Adaptive GPS accuracy to extend battery life during long commutes'),
            secondary: Icon(Icons.battery_saver, color: Theme.of(context).colorScheme.secondary),
            value: _powerSaving,
            onChanged: (value) async {
              setState(() => _powerSaving = value);
              await SettingsService().setPowerSavingMode(value);
              LocationService().refreshBatterySettings();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value ? 'Power Saving active: GPS interval extended' : 'High Accuracy active: GPS interval shortened'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          ListTile(
            title: const Text('Background Optimization'),
            subtitle: const Text('Ensure TaraTren isn\'t closed by the system during long train rides'),
            leading: Icon(Icons.flash_on, color: Theme.of(context).colorScheme.secondary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showBatteryOptimizationInstructions();
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('System Status', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          const ListTile(
            title: Text('High Accuracy Tracking'),
            subtitle: Text('Optimized for low-jitter movement data'),
            trailing: Icon(Icons.check_circle, color: Colors.green),
          ),
          const ListTile(
            title: Text('Background Monitoring'),
            subtitle: Text('Persistence enabled for arrival alerts'),
            trailing: Icon(Icons.check_circle, color: Colors.green),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Account Management', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text('Permanently remove all your data'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            trailing: _isDeleting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
            onTap: _isDeleting ? null : _handleDeleteAccount,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('About', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('About the Developer'),
            subtitle: const Text('Meet the creator of TaraTren'),
            leading: Icon(Icons.person_pin, color: Theme.of(context).colorScheme.secondary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutDeveloperScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Legal & Privacy Info'),
            subtitle: const Text('DPA 2012, Terms, and Disclaimers'),
            leading: Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LegalInfoScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'These settings are recommended for the best experience while commuting in Metro Manila.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'v0.3.0',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeCard(ThemeMode mode, IconData icon, String label) {
    final bool isSelected = _themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() => _themeMode = mode);
          await SettingsService().setThemeMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserTypeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Fare Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _typeOption("Single Journey", "normal"),
              _typeOption("Beep Card User", "beep"),
              _typeOption("Senior Citizen", "senior"),
              _typeOption("Student", "student"),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _typeOption(String label, String type) {
    return RadioListTile<String>(
      title: Text(label),
      value: type,
      groupValue: _userType,
      onChanged: (value) async {
        if (value != null) {
          setState(() => _userType = value);
          await SettingsService().setUserType(value);
          if (mounted) Navigator.pop(context);
        }
      },
    );
  }

  void _showBatteryOptimizationInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.orange),
            SizedBox(width: 10),
            Text('Battery Alert'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To ensure station alerts work while your screen is off, please disable "Battery Optimization" for TaraTren.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('1. Go to App Info > Battery'),
            Text('2. Select "Unrestricted" or "All Apps"'),
            Text('3. Toggle off optimization for TaraTren'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              // Open battery optimization specifically
              AppSettings.openAppSettings(type: AppSettingsType.batteryOptimization);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will permanently delete your profile, saved routes, and trip history. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await _auth.deleteAccount();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }
}
