import 'package:flutter/cupertino.dart';
import 'package:material_query_app/app_navigator.dart';
import 'package:material_query_app/screens/splash_screen.dart';
import 'package:material_query_app/theme/app_theme.dart';
import 'package:material_query_app/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  runApp(const MaterialQueryApp());
}

class MaterialQueryApp extends StatelessWidget {
  const MaterialQueryApp({super.key});

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
