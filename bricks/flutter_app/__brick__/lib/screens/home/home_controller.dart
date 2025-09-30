import 'package:flutter/material.dart';
import 'home_route.dart';
import 'home_view.dart';

/// Controller for the home screen that manages state and business logic.
///
/// Extends State<HomeRoute> to provide state management capabilities
/// and serves as the bridge between the route and view components.
/// All user interactions and state changes are handled here.
class HomeController extends State<HomeRoute> {
  /// Current counter value displayed on the home screen.
  ///
  /// This demonstrates basic state management within the controller.
  /// The counter is incremented when the user taps the floating action button.
  int _counter = 0;

  /// Increments the counter value and triggers a UI rebuild.
  ///
  /// This method demonstrates how user interactions are handled in the
  /// controller layer, with setState() triggering view updates.
  void incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  /// Getter for the current counter value.
  ///
  /// Provides read-only access to the counter state for the view layer.
  int get counter => _counter;

  @override
  Widget build(BuildContext context) => HomeView(this);
}
