import 'package:flutter/cupertino.dart';
import 'package:material_query_app/config/app_config.dart';
import 'package:material_query_app/models/auth_exception.dart';
import 'package:material_query_app/screens/app_center_screen.dart';
import 'package:material_query_app/screens/registration_pending_screen.dart';
import 'package:material_query_app/services/auth_service.dart';
import 'package:material_query_app/services/version_service.dart';
import 'package:material_query_app/theme/app_theme.dart';
import 'package:material_query_app/theme/theme_aware.dart';
import 'package:material_query_app/widgets/app_page_shell.dart';
import 'package:material_query_app/widgets/common_widgets.dart';
import 'package:material_query_app/widgets/corporate_email_field.dart';
import 'package:material_query_app/widgets/theme_toggle_button.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with ThemeAwareState {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _isBusy = false;
  String? _versionMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isBusy = true);

    try {
      if (_isLoginMode) {
        await _login();
      } else {
        await _register();
      }
    } on AuthException catch (error) {
      if (mounted) {
        _showAlert(_isLoginMode ? '登录失败' : '注册失败', error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      throw AuthException('请输入账号密码', code: AuthErrorCode.invalidInput.name);
    }

    final success = await AuthService.instance.login(username, password);
    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute<void>(builder: (_) => const AppCenterScreen()),
      );
    }
  }

  Future<void> _register() async {
    final result = await AuthService.instance.register(
      RegistrationRequest(
        emailLocalPart: _emailController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      ),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(
        builder: (_) => RegistrationPendingScreen(
          email: result.email,
          username: result.username,
        ),
      ),
    );
  }

  Future<void> _checkVersion() async {
    setState(() {
      _isBusy = true;
      _versionMessage = null;
    });

    final info = await VersionService.instance.checkForUpdate();
    if (!mounted) {
      return;
    }

    setState(() {
      _isBusy = false;
      _versionMessage = info.updateAvailable
          ? 'Update available: v${info.latestVersion} (current v${info.currentVersion})'
          : '您当前使用的是最新版本(v${info.currentVersion}).';
    });

    if (info.updateAvailable) {
      final shouldDownload = await _showConfirm(
        'Update available',
        'Version ${info.latestVersion} is available. Download now?',
      );
      if (shouldDownload == true) {
        await _openDownload(info.downloadUrl);
      }
    }
  }

  Future<void> _openDownload(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showAlert('下载失败', '未获取下载链接');
    }
  }

  void _contactDeveloper() {
    _showAlert('联系作者', AppConfig.developerEmail);
  }

  Future<void> _showAlert(String title, String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirm(String title, String message) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('下载'),
          ),
        ],
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      if (_isLoginMode) {
        _emailController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageShell(
      navigationBar: CupertinoNavigationBar(
        middle: Text('易视库', style: AppTheme.navTitle),
        backgroundColor: AppColors.surface,
      ),
      bottomRight: Container(
        decoration: BoxDecoration(
          color: AppColors.accentTint,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CupertinoButton(
          padding: ThemeToggleButton.buttonPadding,
          minimumSize: Size.zero,
          onPressed: _contactDeveloper,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '关于软件',
                style: TextStyle(
                  inherit: false,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentDark,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.envelope_fill,
                size: ThemeToggleButton.iconSize,
                color: AppColors.accent.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
          children: [
            const SizedBox(height: 12),
            Text(_isLoginMode ? '账号登录' : '账号注册', style: AppTheme.navLargeTitle),
            const SizedBox(height: 8),
            if (!_isLoginMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '本应用仅供SSME员工注册使用',
                  style: AppTheme.secondary.copyWith(fontSize: 14),
                ),
              ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isLoginMode) ...[
                    Text(
                      '邮箱',
                      style: TextStyle(
                        inherit: false,
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CorporateEmailField(controller: _emailController),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    '用户名',
                    style: TextStyle(
                      inherit: false,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _usernameController,
                    placeholder: '请输入用户名',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '密码',
                    style: TextStyle(
                      inherit: false,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _passwordController,
                    placeholder: '请输入密码',
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  AppPrimaryButton(
                    label: _isLoginMode ? '登录账号' : '注册账号',
                    isLoading: _isBusy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 10),
                  AppSecondaryButton(
                    label: _isLoginMode ? '注册账号' : '已有账号？登录',
                    onPressed: _isBusy ? () {} : _toggleMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('软件版本', style: AppTheme.sectionTitle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('检查并获取最新版本软件', style: AppTheme.secondary),
                  if (_versionMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(_versionMessage!, style: AppTheme.success),
                  ],
                  const SizedBox(height: 14),
                  AppSecondaryButton(
                    label: '检查更新',
                    onPressed: _isBusy ? () {} : _checkVersion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
