import 'package:flutter/cupertino.dart';
import 'package:material_query_app/theme/theme_controller.dart';

/// Rebuilds [builder] whenever light/dark mode changes.
class ThemeAwareBuilder extends StatelessWidget {
  const ThemeAwareBuilder({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) => builder(context),
    );
  }
}

/// Adds a [ThemeController] listener so [State.build] runs on theme changes.
mixin ThemeAwareState<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}
