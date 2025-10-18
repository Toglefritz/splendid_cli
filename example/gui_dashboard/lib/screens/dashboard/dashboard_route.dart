import 'package:flutter/material.dart';

import 'dashboard_controller.dart';

/// Route widget for the main dashboard screen.
///
/// This route serves as the entry point for the Splendid CLI GUI Dashboard, providing access to all CLI functionality
/// through a visual interface. It follows the MVC pattern by delegating state management to the controller.
///
/// The dashboard provides access to:
/// * Project creation with platform selection
/// * Screen generation with MVC architecture
/// * Test file generation tools
/// * Project formatting and setup utilities
/// * File system navigation and project management
class DashboardRoute extends StatefulWidget {
  /// Creates a new dashboard route.
  const DashboardRoute({super.key});

  @override
  State<DashboardRoute> createState() => DashboardController();
}
