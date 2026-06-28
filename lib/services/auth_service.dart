import 'package:material_query_app/config/auth_config.dart';
import 'package:material_query_app/models/auth_exception.dart';
import 'package:material_query_app/services/auth_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationRequest {
  const RegistrationRequest({
    required this.emailLocalPart,
    required this.username,
    required this.password,
  });

  final String emailLocalPart;
  final String username;
  final String password;
}

class RegistrationResult {
  const RegistrationResult({
    required this.email,
    required this.username,
  });

  final String email;
  final String username;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _sessionKey = 'current_user';
  static const _tokenKey = 'auth_token';

  static const emailDomain = AuthConfig.emailDomain;

  static String buildEmail(String localPart) {
    var local = localPart.trim().toLowerCase();
    if (local.contains('@')) {
      final parts = local.split('@');
      local = parts.first;
    }
    return '$local$emailDomain';
  }

  static String? validateEmailLocalPart(String localPart) {
    final local = localPart.trim().toLowerCase();
    if (local.isEmpty) {
      return '请输入邮箱';
    }
    if (local.contains('@')) {
      return '无需输入邮箱后缀';
    }
    if (!RegExp(r'^[a-z0-9._+-]+$').hasMatch(local)) {
      return '邮箱格式无效';
    }
    return null;
  }

  static String? validateUsername(String username) {
    final value = username.trim();
    if (value.isEmpty) {
      return '请输入用户名';
    }
    if (value.length < 3) {
      return '用户名至少 3 个字符';
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value)) {
      return '用户名只能包含字母、数字、点、下划线和连字符';
    }
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return '请输入密码';
    }
    if (password.length < 4) {
      return '密码至少 4 位';
    }
    return null;
  }

  Future<RegistrationResult> register(RegistrationRequest request) async {
    final emailError = validateEmailLocalPart(request.emailLocalPart);
    if (emailError != null) {
      throw AuthException(emailError, code: AuthErrorCode.invalidInput.name);
    }

    final usernameError = validateUsername(request.username);
    if (usernameError != null) {
      throw AuthException(usernameError, code: AuthErrorCode.invalidInput.name);
    }

    final passwordError = validatePassword(request.password);
    if (passwordError != null) {
      throw AuthException(passwordError, code: AuthErrorCode.invalidInput.name);
    }

    final email = buildEmail(request.emailLocalPart);
    final username = request.username.trim();

    try {
      final response = await AuthApiService.instance.register(
        email: email,
        username: username,
        password: request.password,
      );

      if (response.confirmed) {
        throw AuthException(
          '注册成功，但账号已直接激活。请确认服务器已启用邮箱激活流程。',
          code: AuthErrorCode.server.name,
        );
      }

      return RegistrationResult(email: email, username: username);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
        AuthErrorCode.network.defaultMessage,
        code: AuthErrorCode.network.name,
      );
    }
  }

  Future<bool> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      throw AuthException('请输入用户名和密码', code: AuthErrorCode.invalidInput.name);
    }

    final normalized = username.trim();

    try {
      final response = await AuthApiService.instance.login(
        username: normalized,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, response.username);
      if (response.token != null) {
        await prefs.setString(_tokenKey, response.token!);
      }
      return true;
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
        AuthErrorCode.network.defaultMessage,
        code: AuthErrorCode.network.name,
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_tokenKey);
  }

  Future<String?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }
}
