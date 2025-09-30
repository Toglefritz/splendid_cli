import 'package:flutter/material.dart';
import 'home_controller.dart';

/// View widget for the home screen that handles UI presentation.
///
/// This StatelessWidget receives the controller as a parameter and
/// uses it to access state and trigger actions. The view contains
/// no business logic and is purely declarative.
class HomeView extends StatelessWidget {
  /// Creates the home view with the required controller.
  ///
  /// The controller provides access to state data and action methods
  /// needed for rendering and user interaction handling.
  const HomeView(this.controller, {super.key});

  /// Controller instance that manages state and business logic.
  ///
  /// Used to access the current lamp state and trigger toggle actions.
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('{{name.titleCase()}}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            /// Lamp icon that changes appearance based on state.
            ///
            /// When the lamp is on, it displays a bright yellow bulb with glow effect.
            /// When off, it displays a dim gray bulb without glow.
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: controller.isLampOn
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.lightbulb,
                size: 80,
                color: controller.isLampOn ? Colors.amber : Colors.grey,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('OFF'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Switch(
                      value: controller.isLampOn,
                      onChanged: controller.toggleLamp,
                      activeColor: Colors.amber,
                    ),
                  ),
                  const Text('ON'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
