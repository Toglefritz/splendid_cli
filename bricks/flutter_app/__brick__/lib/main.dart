/// Main entry point for the {{name}} Flutter application.
///
/// This file serves as the application entry point and is responsible only
/// for initializing and running the Flutter app. The main application widget
/// is defined in a separate file following the one-class-per-file principle.

import 'package:flutter/material.dart';
import 'app.dart';

/// Application entry point that initializes and runs the Flutter app.
///
/// This function is called when the application starts and creates an instance
/// of the main application widget. All application configuration and setup
/// is handled by the {{name.pascalCase()}} widget in app.dart.
void main() {
  runApp(
    const {{name.pascalCase()}}(),
  );
}
