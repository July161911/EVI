import 'package:flutter/cupertino.dart';
import 'package:evi/screens/login_screen.dart';
import 'package:evi/theme/app_theme.dart';
import 'package:evi/theme/theme_aware.dart';
import 'package:evi/widgets/app_page_shell.dart';
import 'package:evi/widgets/common_widgets.dart';

class RegistrationPendingScreen extends StatelessWidget {
  const RegistrationPendingScreen({
    super.key,
    required this.email,
    required this.username,
  });

  final String email;
  final String username;

  @override
  Widget build(BuildContext context) {
    return ThemeAwareBuilder(
      builder: (context) {
        return AppPageShell(
          navigationBar: CupertinoNavigationBar(
            middle: Text('等待激活', style: AppTheme.navTitle),
            backgroundColor: AppColors.surface,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('请激活账号', style: AppTheme.navLargeTitle),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          CupertinoIcons.mail_solid,
                          color: AppColors.accent,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text('我们已向以下邮箱发送激活邮件：', style: AppTheme.secondary),
                        const SizedBox(height: 8),
                        Text(email, style: AppTheme.sectionTitle),
                        const SizedBox(height: 8),
                        Text(
                          '用户名：$username',
                          style: AppTheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '请查收邮箱，点击邮件中的激活链接打开网页完成账号激活。'
                          '激活成功后，返回本应用登录即可使用。',
                          style: AppTheme.secondary.copyWith(height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '如未收到邮件，请检查垃圾邮件文件夹。',
                          style: AppTheme.secondary.copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AppSecondaryButton(
                    label: '返回登录',
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        CupertinoPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
