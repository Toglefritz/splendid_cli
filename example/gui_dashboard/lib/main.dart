import 'package:flutter/material.dart';
import 'splendid_cli_gui_app.dart';

/// Entry point for the Splendid CLI GUI Dashboard application.
///
/// This Flutter desktop application provides a graphical interface for using
/// the Splendid CLI tools. It offers point-and-click access to project
/// creation, screen generation, test file creation, and other CLI
/// functionality.
///
/// The application follows the MVC architecture pattern established by the
/// Splendid CLI project, with proper separation of concerns between routes,
/// controllers, and views.
void main() {
  runApp(const SplendidCliGuiApp());
}
