import 'package:flutter/cupertino.dart';
import 'package:evi/screens/material_search_screen.dart';
import 'package:evi/screens/reserved_screen.dart';
import 'package:evi/theme/app_theme.dart';
import 'package:evi/theme/theme_aware.dart';
import 'package:evi/widgets/app_page_shell.dart';
import 'package:evi/widgets/common_widgets.dart';

class AppCenterScreen extends StatelessWidget {
  const AppCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeAwareBuilder(
      builder: (context) {
        return AppPageShell(
          navigationBar: CupertinoNavigationBar(
            middle: Text('易视库', style: AppTheme.navTitle),
            backgroundColor: AppColors.surface,
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
              children: [
                Text('应用中心', style: AppTheme.navLargeTitle),
                const SizedBox(height: 8),
                const SizedBox(height: 24),
                _ModuleTile(
                  title: '紧固件',
                  subtitle: '看板紧固件库查询 物料位置查询',
                  accent: AppColors.primary,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => const MaterialSearchScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ModuleTile(
                  title: '工具',
                  subtitle: '工具封存库查询 APLab库查询',
                  accent: AppColors.accent,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => const ReservedScreen(pageNumber: 5),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ModuleTile(
                  title: '供应商',
                  subtitle: '供应商库存查询',
                  accent: AppColors.accent,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => const ReservedScreen(pageNumber: 6),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(CupertinoIcons.square_grid_2x2_fill, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      inherit: false,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.secondary.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
