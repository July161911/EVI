import 'package:flutter/cupertino.dart';
import 'package:evi/theme/app_theme.dart';
import 'package:evi/theme/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  static const double iconSize = 18;
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDark;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.toggleBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.toggleBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeModeIconButton(
                icon: CupertinoIcons.sun_max_fill,
                isActive: !isDark,
                onPressed: () => ThemeController.instance.setDarkMode(false),
              ),
              _ThemeModeIconButton(
                icon: CupertinoIcons.moon_fill,
                isActive: isDark,
                onPressed: () => ThemeController.instance.setDarkMode(true),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeModeIconButton extends StatelessWidget {
  const _ThemeModeIconButton({
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: ThemeToggleButton.buttonPadding,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Icon(
        icon,
        size: ThemeToggleButton.iconSize,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}
