import 'package:flutter/material.dart';
import '{{name.snakeCase()}}_route.dart';
import '{{name.snakeCase()}}_view.dart';

/// Controller for the {{name.lowerCase()}} screen that manages state and business logic.
///
/// Extends `State<{{name.pascalCase()}}Route>` to provide state management capabilities and serves as the bridge
/// between the route and view components. Add your business logic and state management here.
class {{name.pascalCase()}}Controller extends State<{{name.pascalCase()}}Route> {
  @override
  Widget build(BuildContext context) => {{name.pascalCase()}}View(this);
}