import 'package:flutter/material.dart';
import '{{name.snakeCase()}}_controller.dart';

/// View widget for the {{name.lowerCase()}} screen that handles UI presentation.
///
/// This StatelessWidget receives the controller as a parameter and uses it to access state and trigger actions. The
/// view contains no business logic and is purely declarative, displaying the icon selection game interface.
class {{name.pascalCase()}}View extends StatelessWidget {
  /// Creates the {{name.lowerCase()}} view with the required controller.
  const {{name.pascalCase()}}View(this.controller, {super.key});

  /// Controller instance that manages state and business logic.
  ///
  /// Used to access the current game state and trigger icon selection actions.
  final {{name.pascalCase()}}Controller controller;

   /// Returns a human-readable name for the given icon.
  ///
  /// Maps Material icon constants to user-friendly names for display in the instruction text.
  ///
  /// Parameters:
  /// * [icon] - The IconData to get a name for
  ///
  /// Returns:
  /// * String representation of the icon name
  String _getIconName(IconData icon) {
    switch (icon) {
      case Icons.rocket_launch:
        return 'rocket';
      case Icons.restaurant_menu:
        return 'chef hat';
      case Icons.palette:
        return 'art palette';
      default:
        return 'icon';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('{{name.titleCase()}}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (controller.targetIcon != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Text(
                  'Select the ${_getIconName(controller.targetIcon!)}',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: controller.currentIcons.map((IconData icon) {
                return GestureDetector(
                  onTap: () => controller.onIconSelected(icon),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}