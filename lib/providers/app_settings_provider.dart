import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  final StorageService storage;
  late ThemeMode themeMode;
  AppSettingsProvider(this.storage) { themeMode = _parse(storage.getThemeMode()); }
  static ThemeMode _parse(String value) => switch (value) {'light' => ThemeMode.light, 'dark' => ThemeMode.dark, _ => ThemeMode.system};
  Future<void> setThemeMode(ThemeMode mode) async { themeMode = mode; await storage.setThemeMode(switch(mode){ThemeMode.light=>'light',ThemeMode.dark=>'dark',_=>'system'}); notifyListeners(); }
}
