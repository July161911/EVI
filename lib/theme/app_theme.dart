import 'package:flutter/cupertino.dart';
import 'package:evi/theme/theme_controller.dart';

class AppPalette {
  const AppPalette({
    required this.white,
    required this.background,
    required this.surface,
    required this.primaryLight,
    required this.accentLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.separator,
    required this.shadow,
    required this.toggleBackground,
    required this.toggleBorder,
  });

  final Color white;
  final Color background;
  final Color surface;
  final Color primaryLight;
  final Color accentLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color separator;
  final Color shadow;
  final Color toggleBackground;
  final Color toggleBorder;

  static const AppPalette light = AppPalette(
    white: Color(0xFFFFFFFF),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    primaryLight: Color(0xFFFFF0E6),
    accentLight: Color(0xFFE6F7F7),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF8E8E93),
    separator: Color(0xFFEEEEEE),
    shadow: Color(0x1A000000),
    toggleBackground: Color(0xFFF2F2F7),
    toggleBorder: Color(0xFFE5E5EA),
  );

  static const AppPalette dark = AppPalette(
    white: Color(0xFFFFFFFF),
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    primaryLight: Color(0xFF3D2A1A),
    accentLight: Color(0xFF1A3333),
    textPrimary: Color(0xFFF2F2F7),
    textSecondary: Color(0xFFAEAEB2),
    separator: Color(0xFF3A3A3C),
    shadow: Color(0x66000000),
    toggleBackground: Color(0xFF2C2C2E),
    toggleBorder: Color(0xFF48484A),
  );
}

/// Brand and semantic colors plus theme-aware surfaces via [ThemeController].
abstract final class AppColors {
  static AppPalette get _palette => ThemeController.instance.isDark
      ? AppPalette.dark
      : AppPalette.light;

  static Color get white => _palette.white;
  static Color get background => _palette.background;
  static Color get surface => _palette.surface;

  static const Color primary = Color(0xFFEC6602);
  static const Color primaryLight = Color(0xFFFFF0E6);
  static const Color primaryDark = Color(0xFFC55502);

  static const Color accent = Color(0xFF009999);
  static const Color accentLight = Color(0xFFE6F7F7);
  static const Color accentDark = Color(0xFF007A7A);

  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get separator => _palette.separator;
  static Color get shadow => _palette.shadow;
  static Color get toggleBackground => _palette.toggleBackground;
  static Color get toggleBorder => _palette.toggleBorder;

  static Color get primaryTint => ThemeController.instance.isDark
      ? AppPalette.dark.primaryLight
      : AppPalette.light.primaryLight;

  static Color get accentTint => ThemeController.instance.isDark
      ? AppPalette.dark.accentLight
      : AppPalette.light.accentLight;

  static const Color error = Color(0xFFFF3B30);
}

abstract final class AppTheme {
  static TextStyle get body => TextStyle(
        inherit: false,
        fontSize: 17,
        color: AppColors.textPrimary,
        letterSpacing: -0.41,
      );

  static TextStyle get navTitle => TextStyle(
        inherit: false,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.41,
      );

  static TextStyle get navLargeTitle => TextStyle(
        inherit: false,
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: 0.37,
      );

  static TextStyle get secondary => TextStyle(
        inherit: false,
        fontSize: 17,
        color: AppColors.textSecondary,
        letterSpacing: -0.41,
      );

  static TextStyle get accentPrimary => TextStyle(
        inherit: false,
        fontSize: 17,
        color: AppColors.primary,
        letterSpacing: -0.41,
      );

  static TextStyle get accentTeal => TextStyle(
        inherit: false,
        fontSize: 17,
        color: AppColors.accent,
        letterSpacing: -0.41,
      );

  static TextStyle get sectionTitle => TextStyle(
        inherit: false,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get success => TextStyle(
        inherit: false,
        fontSize: 17,
        color: AppColors.accentDark,
      );

  static CupertinoThemeData get cupertino => CupertinoThemeData(
        brightness:
            ThemeController.instance.isDark ? Brightness.dark : Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        barBackgroundColor: AppColors.surface,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.textPrimary,
          textStyle: body,
          navTitleTextStyle: navTitle,
          navLargeTitleTextStyle: navLargeTitle,
        ),
      );
}
