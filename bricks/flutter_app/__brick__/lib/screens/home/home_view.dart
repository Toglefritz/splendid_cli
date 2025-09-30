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
  /// Used to access the current counter value and trigger increment actions.
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
            const Text(
              'You have pushed the button this many times:',
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                '${controller.counter}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
