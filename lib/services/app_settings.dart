import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppSettings {
  static late Box _settingsBox;

  static Future<void> init() async {
    _settingsBox = await Hive.openBox('app_settings');
  }

  // Theme settings
  static ThemeMode get themeMode {
    final value = _settingsBox.get('theme_mode', defaultValue: 'system');
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static set themeMode(ThemeMode mode) {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      default:
        value = 'system';
        break;
    }
    _settingsBox.put('theme_mode', value);
  }

  // AI settings
  static String get aiBaseUrl => _settingsBox.get(
    'ai_base_url',
    defaultValue: 'http://localhost:11434/v1',
  );
  static set aiBaseUrl(String url) => _settingsBox.put('ai_base_url', url);

  static String get aiModel =>
      _settingsBox.get('ai_model', defaultValue: 'qwen2.5-coder:7b');
  static set aiModel(String model) => _settingsBox.put('ai_model', model);

  static String get aiApiKey =>
      _settingsBox.get('ai_api_key', defaultValue: '');
  static set aiApiKey(String key) => _settingsBox.put('ai_api_key', key);

  static bool get countTokens =>
      _settingsBox.get('count_tokens', defaultValue: false);
  static set countTokens(bool key) => _settingsBox.put('count_tokens', key);

  static int get aiMaxTokens =>
      _settingsBox.get('ai_max_tokens', defaultValue: 4096);
  static set aiMaxTokens(int tokens) =>
      _settingsBox.put('ai_max_tokens', tokens);

  static double get aiTemperature =>
      _settingsBox.get('ai_temperature', defaultValue: 0.7);
  static set aiTemperature(double temp) =>
      _settingsBox.put('ai_temperature', temp);

  // Window settings
  static bool get rememberWindowSize =>
      _settingsBox.get('remember_window_size', defaultValue: true);
  static set rememberWindowSize(bool remember) =>
      _settingsBox.put('remember_window_size', remember);

  static Size get windowSize => Size(
    _settingsBox.get('window_width', defaultValue: 1280.0),
    _settingsBox.get('window_height', defaultValue: 800.0),
  );

  static set windowSize(Size size) {
    _settingsBox.put('window_width', size.width);
    _settingsBox.put('window_height', size.height);
  }

  // Auto-save settings
  static bool get autoSaveEnabled =>
      _settingsBox.get('auto_save_enabled', defaultValue: true);
  static set autoSaveEnabled(bool enabled) =>
      _settingsBox.put('auto_save_enabled', enabled);
}
