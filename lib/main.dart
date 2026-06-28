import 'package:flutter/cupertino.dart';
import 'package:evi/app_navigator.dart';
import 'package:evi/screens/splash_screen.dart';
import 'package:evi/theme/app_theme.dart';
import 'package:evi/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  runApp(const EviApp());
}

class EviApp extends StatelessWidget {
  const EviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return CupertinoApp(
          navigatorKey: appNavigatorKey,
          title: 'EVI',
          theme: AppTheme.cupertino,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
