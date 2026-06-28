import 'package:flutter/cupertino.dart';
import 'package:evi/theme/app_theme.dart';
import 'package:evi/theme/theme_aware.dart';
import 'package:evi/widgets/app_page_shell.dart';
import 'package:evi/widgets/common_widgets.dart';

class ReservedScreen extends StatelessWidget {
  const ReservedScreen({super.key, required this.pageNumber});

  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return ThemeAwareBuilder(
      builder: (context) {
        return AppPageShell(
          navigationBar: CupertinoNavigationBar(
            middle: Text('Page $pageNumber', style: AppTheme.navTitle),
            backgroundColor: AppColors.surface,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accentTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.time,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '开发中',
                      style: AppTheme.navTitle.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '此功能正在开发中，敬请期待。',
                      style: TextStyle(
                        inherit: false,
                        color: AppColors.textSecondary,
                        fontSize: 17,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
