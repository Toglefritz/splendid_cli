import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/dashboard/dashboard_route.dart';

/// Entry point for the Splendid CLI GUI Dashboard application.
///
/// This Flutter desktop application provides a graphical interface for using the Splendid CLI tools. It offers
/// point-and-click access to project creation, screen generation, test file creation, and other CLI functionality.
///
/// The application follows the MVC architecture pattern established by the Splendid CLI project, with proper separation
/// of concerns between routes, controllers, and views.
void main() {
  runApp(const SplendidCliGuiApp());
}

/// Root application widget for the Splendid CLI GUI Dashboard.
///
/// This widget configures the MaterialApp with appropriate theming, localization, and routing for the desktop GUI
/// interface.
///
/// The application uses Material Design 3 with a custom color scheme that reflects the Splendid CLI branding and
/// provides a professional development tool appearance.
class SplendidCliGuiApp extends StatelessWidget {
  /// Creates the root application widget.
  const SplendidCliGuiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splendid CLI Dashboard',
      debugShowCheckedModeBanner: false,

      // Localization configuration
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],

      // Theme configuration
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Dark theme configuration
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Use system theme mode
      themeMode: ThemeMode.system,

      // Set the dashboard as the home screen
      home: const DashboardRoute(),
    );
  }
}
