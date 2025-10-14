import 'dart:math';
import 'package:flutter/material.dart';
import '{{name.snakeCase()}}_route.dart';
import '{{name.snakeCase()}}_view.dart';

/// Controller for the {{name.lowerCase()}} screen that manages state and business logic.
///
/// Extends `State<{{name.pascalCase()}}Route>` to provide state management capabilities and serves as the bridge between the route and
/// view components. Manages the icon selection game logic including randomization and user interactions.
class {{name.pascalCase()}}Controller extends State<{{name.pascalCase()}}Route> {
  /// Available icons for the selection game.
  ///
  /// Contains the three Material icons that users can select from: rocket, chef hat, and art palette.
  static const List<IconData> _availableIcons = [
    Icons.rocket_launch,
    Icons.restaurant_menu,
    Icons.palette,
  ];

  /// Current arrangement of icons displayed to the user.
  ///
  /// This list is shuffled each time the game resets to provide variety in icon positioning.
  List<IconData> _currentIcons = [];

  /// The icon that the user should select to win the current round.
  ///
  /// Randomly chosen from the available icons when the game starts or resets.
  IconData? _targetIcon;

  /// Random number generator for shuffling icons and selecting targets.
  ///
  /// Used to ensure unpredictable game behavior and maintain user engagement.
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  /// Resets the game by shuffling icons and selecting a new target.
  ///
  /// This method is called during initialization and after each successful selection
  /// to provide a new challenge for the user.
  void _resetGame() {
    setState(() {
      _currentIcons = List.from(_availableIcons)..shuffle(_random);
      _targetIcon = _availableIcons[_random.nextInt(_availableIcons.length)];
    });
  }

  /// Handles user icon selection and game progression.
  ///
  /// When the user selects the correct icon, the game resets with a new arrangement.
  /// Incorrect selections have no effect, allowing the user to try again.
  ///
  /// Parameters:
  /// * [selectedIcon] - The icon that the user tapped
  void onIconSelected(IconData selectedIcon) {
    if (selectedIcon == _targetIcon) {
      _resetGame();
    }
  }

  /// Getter for the current icon arrangement.
  ///
  /// Provides read-only access to the shuffled icon list for the view layer.
  List<IconData> get currentIcons => _currentIcons;

  /// Getter for the target icon that should be selected.
  ///
  /// Provides read-only access to the target icon for display in the view.
  IconData? get targetIcon => _targetIcon;

  @override
  Widget build(BuildContext context) => {{name.pascalCase()}}View(this);
}
