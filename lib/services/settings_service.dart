import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String keyVoiceEnabled = 'voice_enabled';
  static const String keyVoiceLanguage = 'voice_language'; // New
  static const String keyOfflineMode = 'offline_mode'; // New
  static const String keyUserType = 'user_type';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyPowerSavingMode = 'power_saving_mode';
  static const String keyVoicePack = 'voice_pack'; 
  static const String keySystemIslandEnabled = 'system_island_enabled';
  static const String keyThemeMode = 'theme_mode'; // New


  late SharedPreferences _prefs;
  
  // Use a ValueNotifier so main.dart can rebuild when theme changes
  final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize the notifier from saved prefs
    final savedTheme = _prefs.getString(keyThemeMode) ?? 'system';
    themeNotifier.value = _themeModeFromString(savedTheme);
  }

  bool get isVoiceEnabled => _prefs.getBool(keyVoiceEnabled) ?? true;
  String get voiceLanguage => _prefs.getString(keyVoiceLanguage) ?? 'both';
  bool get isOfflineMode => _prefs.getBool(keyOfflineMode) ?? false;
  String get userType => _prefs.getString(keyUserType) ?? 'normal';
  bool get hasCompletedOnboarding => _prefs.getBool(keyOnboardingComplete) ?? false;
  bool get isPowerSavingMode => _prefs.getBool(keyPowerSavingMode) ?? false;
  String get voicePack => _prefs.getString(keyVoicePack) ?? 'professional';
  bool get isSystemIslandEnabled => _prefs.getBool(keySystemIslandEnabled) ?? true;
  ThemeMode get themeMode => themeNotifier.value;

  Future<void> setVoiceEnabled(bool value) async {
    await _prefs.setBool(keyVoiceEnabled, value);
  }

  Future<void> setVoiceLanguage(String value) async {
    await _prefs.setString(keyVoiceLanguage, value);
  }

  Future<void> setVoicePack(String value) async {
    await _prefs.setString(keyVoicePack, value);
  }

  Future<void> setOfflineMode(bool value) async {
    await _prefs.setBool(keyOfflineMode, value);
  }

  Future<void> setUserType(String value) async {
    await _prefs.setString(keyUserType, value);
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(keyOnboardingComplete, value);
  }

  Future<void> setPowerSavingMode(bool value) async {
    await _prefs.setBool(keyPowerSavingMode, value);
  }

  Future<void> setSystemIslandEnabled(bool value) async {
    await _prefs.setBool(keySystemIslandEnabled, value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeNotifier.value = mode;
    await _prefs.setString(keyThemeMode, mode.name);
  }

  ThemeMode _themeModeFromString(String value) {
    return ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}

