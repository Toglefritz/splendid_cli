import 'package:flutter/material.dart';
import '{{name.snakeCase()}}_controller.dart';

/// View widget for the {{name.lowerCase()}} screen that handles UI presentation.
///
/// This StatelessWidget receives the controller as a parameter and uses it to access state and trigger actions. The
/// view contains no business logic and is purely declarative.
class {{name.pascalCase()}}View extends StatelessWidget {
  /// Creates the {{name.lowerCase()}} view with the required controller.
  const {{name.pascalCase()}}View(this.state, {super.key});

  /// Controller instance that manages state and business logic.
  ///
  /// Used to access the current state and trigger actions.
  final {{name.pascalCase()}}Controller state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{name.titleCase()}}'),
      ),
      body: const Center(
        child: Text(
          'Welcome to {{name.titleCase()}}',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}