import 'package:flutter/cupertino.dart';
import 'package:material_query_app/theme/app_theme.dart';
import 'package:material_query_app/widgets/theme_toggle_button.dart';

class AppPageShell extends StatelessWidget {
  const AppPageShell({
    super.key,
    this.navigationBar,
    required this.child,
    this.showThemeToggle = true,
    this.bottomRight,
  });

  final ObstructingPreferredSizeWidget? navigationBar;
  final Widget child;
  final bool showThemeToggle;
  final Widget? bottomRight;

  static const EdgeInsets cornerInsets =
      EdgeInsets.only(left: 20, right: 20, bottom: 16);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: navigationBar,
      child: Stack(
        children: [
          child,
          if (showThemeToggle)
            SafeArea(
              minimum: cornerInsets,
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: ThemeToggleButton(),
              ),
            ),
          if (bottomRight != null)
            SafeArea(
              minimum: cornerInsets,
              child: Align(
                alignment: Alignment.bottomRight,
                child: bottomRight!,
              ),
            ),
        ],
      ),
    );
  }
}
