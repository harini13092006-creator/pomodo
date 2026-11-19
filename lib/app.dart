import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'providers/timer_provider.dart';
import 'providers/app_settings_provider.dart';
import 'screens/productivity_screens.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';

/// Root application widget configuring themes, providers, and navigation.
class PomodoApp extends StatelessWidget {
  final StorageService storageService;
  final SoundService? soundService;

  const PomodoApp({
    super.key,
    required this.storageService,
    this.soundService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider<TimerProvider>(
          create: (_) => TimerProvider(
            storageService: storageService,
            soundService: soundService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider(storageService)),
      ],
      child: Consumer<AppSettingsProvider>(builder: (context, settings, _) => MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.themeMode,
        home: const PomodoNavigation(),
      )),
    );
  }
}
