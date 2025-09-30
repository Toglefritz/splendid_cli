/// Root application widget for the {{name}} Flutter application.
/// 
/// This file contains the main application widget that configures the Flutter app
/// with Material Design theming and sets up the initial route to the home screen
/// following MVC architecture patterns.

import 'package:flutter/material.dart';
import 'screens/home/home_route.dart';

/// Root application widget that configures the Flutter app.
/// 
/// This widget serves as the top-level container for the entire application
/// and is responsible for:
/// * Setting up the Material Design theme and color scheme
/// * Configuring the app title and debug settings
/// * Defining the initial route (home screen)
/// * Enabling Material 3 design system
/// 
/// The widget follows the StatelessWidget pattern as it contains no mutable
/// state and serves purely as a configuration container.
class {{name.pascalCase()}} extends StatelessWidget {
  /// Creates the root application widget.
  /// 
  /// This constructor is const to enable compile-time optimization
  /// and follows Flutter best practices for immutable widgets.
  const {{name.pascalCase()}}({super.key});

  /// Builds the widget tree for the root application.
  /// 
  /// Returns a [MaterialApp] configured with:
  /// * App title derived from the project name
  /// * Material 3 design system with deep purple color scheme
  /// * Home route pointing to the main screen
  /// * Debug banner disabled for cleaner presentation
  /// 
  /// The MaterialApp provides the foundation for Material Design components
  /// and navigation throughout the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{name.titleCase()}}',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const HomeRoute(),
      debugShowCheckedModeBanner: false,
    );
  }
}