import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:evi/constants/app_assets.dart';
import 'package:evi/screens/login_screen.dart';
import 'package:evi/theme/app_theme.dart';
import 'package:evi/theme/theme_aware.dart';
import 'package:evi/widgets/app_page_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with ThemeAwareState {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _goToLogin);
  }

  void _goToLogin() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageShell(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const ssmeWidth = 200.0;
            const ssmeHeight = 120.0;
            const julySize = 72.0;

            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              children: [
                Positioned(
                  left: width * 0.5 - ssmeWidth / 2,
                  top: height * 0.38 - ssmeHeight / 2,
                  child: const _SplashBrandImage(
                    assetPath: AppAssets.ssme,
                    width: ssmeWidth,
                    height: ssmeHeight,
                  ),
                ),
                Positioned(
                  right: 24,
                  bottom: 24,
                  child: const _SplashBrandImage(
                    assetPath: AppAssets.july,
                    width: julySize,
                    height: julySize,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashBrandImage extends StatelessWidget {
  const _SplashBrandImage({
    required this.assetPath,
    required this.width,
    required this.height,
  });

  final String assetPath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            assetPath,
            width: width,
            height: height,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
