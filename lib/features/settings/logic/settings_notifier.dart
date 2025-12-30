import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String currency;
  final String dateFormat;
  final ThemeMode themeMode;

  const AppSettings({
    required this.currency,
    required this.dateFormat,
    required this.themeMode,
  });

  AppSettings copyWith({
    String? currency,
    String? dateFormat,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
      : super(const AppSettings(
          currency: 'USD',
          dateFormat: 'MM/dd/yyyy',
          themeMode: ThemeMode.system,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final currency = prefs.getString('currency') ?? 'USD';
    final dateFormat = prefs.getString('dateFormat') ?? 'MM/dd/yyyy';
    final themeName = prefs.getString('themeMode') ?? 'system';
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => ThemeMode.system,
    );

    state = AppSettings(
      currency: currency,
      dateFormat: dateFormat,
      themeMode: themeMode,
    );
  }

  Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    state = state.copyWith(currency: currency);
  }

  Future<void> setDateFormat(String dateFormat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dateFormat', dateFormat);
    state = state.copyWith(dateFormat: dateFormat);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeMode.name);
    state = state.copyWith(themeMode: themeMode);
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
