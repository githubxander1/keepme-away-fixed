import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'screens/onboarding_screen.dart';
import 'utils/prefs.dart';
import 'utils/theme_provider.dart';
import 'utils/language_provider.dart';
import 'services/face_detector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await PrefsHelper.init();
  
  final faceDetector = FaceDetectorService();
  faceDetector.initialize();
  await faceDetector.warmUp();
  
  final themeMode = await AppTheme.getSavedThemeMode();
  final locale = await LanguageProvider.getSavedLocale();
  
  runApp(ScreenProtectorApp(
    initialThemeMode: themeMode,
    initialLocale: locale,
  ));
}

class ScreenProtectorApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final Locale? initialLocale;
  
  const ScreenProtectorApp({
    super.key,
    required this.initialThemeMode,
    this.initialLocale,
  });
  
  static final GlobalKey<_ScreenProtectorAppState> appKey = GlobalKey();
  
  static void setThemeMode(BuildContext context, ThemeMode mode) {
    final state = context.findAncestorStateOfType<_ScreenProtectorAppState>();
    state?.setThemeMode(mode);
  }
  
  static ThemeMode getThemeMode(BuildContext context) {
    final state = context.findAncestorStateOfType<_ScreenProtectorAppState>();
    return state?._themeMode ?? ThemeMode.system;
  }
  
  static void setLocale(BuildContext context, Locale locale) {
    final state = context.findAncestorStateOfType<_ScreenProtectorAppState>();
    state?.setLocale(locale);
  }
  
  static Locale? getLocale(BuildContext context) {
    final state = context.findAncestorStateOfType<_ScreenProtectorAppState>();
    return state?._locale;
  }

  @override
  State<ScreenProtectorApp> createState() => _ScreenProtectorAppState();
}

class _ScreenProtectorAppState extends State<ScreenProtectorApp> {
  late ThemeMode _themeMode;
  Locale? _locale;
  
  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _locale = widget.initialLocale;
  }
  
  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    AppTheme.saveThemeMode(mode);
  }
  
  void setLocale(Locale locale) {
    setState(() => _locale = locale);
    LanguageProvider.saveLocale(locale);
    Intl.defaultLocale = locale.toString();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeepMe Away',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (_locale != null) {
          return _locale;
        }
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      home: const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
