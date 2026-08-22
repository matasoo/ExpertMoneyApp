import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shared_prefs_provider.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeString = prefs.getString(_themeKey);
    
    if (themeString == 'light') return ThemeMode.light;
    if (themeString == 'dark') return ThemeMode.dark;
    
    // Default to dark theme for ExpertMoney
    return ThemeMode.dark;
  }

  Future<void> toggleTheme() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await prefs.setString(_themeKey, 'light');
    } else {
      state = ThemeMode.dark;
      await prefs.setString(_themeKey, 'dark');
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = mode;
    await prefs.setString(_themeKey, mode == ThemeMode.light ? 'light' : 'dark');
  }
}
