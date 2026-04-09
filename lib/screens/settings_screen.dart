import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import '../services/settings_service.dart';
import '../services/location_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'legal_info_screen.dart';
import 'about_developer_screen.dart';
import '../services/system_overlay_service.dart';

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

  @override
  void initState() {
    super.initState();
    _voiceEnabled = SettingsService().isVoiceEnabled;
    _offlineMode = SettingsService().isOfflineMode;
    _powerSaving = SettingsService().isPowerSavingMode;
    _voiceLanguage = SettingsService().voiceLanguage;
    _voicePack = SettingsService().voicePack;
    _userType = SettingsService().userType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Notifications', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Voice Announcements'),
            subtitle: const Text('Speak station arrivals and alerts'),
            secondary: const Icon(Icons.record_voice_over, color: Colors.indigo),
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
              leading: const Icon(Icons.translate, color: Colors.indigo),
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
              leading: const Icon(Icons.style, color: Colors.indigo),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Data & Connectivity', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Offline Mode'),
            subtitle: const Text('Save data and battery. Station alerts and voice announcements still work via GPS.'),
            secondary: const Icon(Icons.signal_wifi_off, color: Colors.indigo),
            value: _offlineMode,
            onChanged: (value) async {
              setState(() => _offlineMode = value);
              await SettingsService().setOfflineMode(value);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Fare Profile', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('Travel Card Type'),
            subtitle: Text(_userType == 'normal' ? 'Single Journey (Full Fare)' : 
                           _userType == 'beep' ? 'Beep Card (Standard Discount)' : 
                           _userType == 'senior' ? 'Senior Citizen (50% Off)' : 'Student (50% Off)'),
            leading: const Icon(Icons.credit_card, color: Colors.indigo),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () {
               _showUserTypeDialog();
            },
          ),
          FutureBuilder<bool>(
            future: FlutterOverlayWindow.isPermissionGranted(),
            builder: (context, snapshot) {
              final permissionGranted = snapshot.data ?? false;
              final bool isEnabled = SettingsService().isSystemIslandEnabled;

              return SwitchListTile(
                title: const Text('System Dynamic Island'),
                subtitle: Text(!permissionGranted 
                  ? 'Tap to grant overlay permission' 
                  : (isEnabled ? 'Floating pill active' : 'Floating pill disabled')),
                secondary: const Icon(Icons.layers, color: Colors.indigo),
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
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Battery & Optimization', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Power Saving Mode'),
            subtitle: const Text('Adaptive GPS accuracy to extend battery life during long commutes'),
            secondary: const Icon(Icons.battery_saver, color: Colors.orange),
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
            leading: const Icon(Icons.flash_on, color: Colors.orange),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showBatteryOptimizationInstructions();
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('System Status', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('About', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('About the Developer'),
            subtitle: const Text('Meet the creator of TaraTren'),
            leading: const Icon(Icons.person_pin, color: Colors.redAccent),
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
            leading: const Icon(Icons.description, color: Colors.indigo),
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
                const Text(
                  'v0.2.1-Alpha',
                  style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
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
}
