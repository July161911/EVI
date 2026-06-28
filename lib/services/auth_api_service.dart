import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_query_app/config/auth_config.dart';
import 'package:material_query_app/models/auth_exception.dart';

class RegisterResponse {
  const RegisterResponse({
    required this.username,
    required this.confirmed,
    required this.status,
  });

  final String username;
  final bool confirmed;
  final String status;
}

class AuthApiService {
  AuthApiService._();
  static final AuthApiService instance = AuthApiService._();

  bool get isConfigured =>
      !AuthConfig.apiBaseUrl.contains('your-server.example.com');

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse(
      '${AuthConfig.apiBaseUrl}$path',
    ).replace(queryParameters: query);
  }

  Future<RegisterResponse> register({
    required String email,
    required String username,
    required String password,
  }) async {
    _ensureConfigured();
    final response = await http
        .post(
          _uri('/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'username': username,
            'password': password,
            'requireEmailConfirmation': true,
            'activationLinkBaseUrl': AuthConfig.activationWebBaseUrl,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return _parseRegisterResponse(response.body, username);
    }

    throw _mapError(response);
  }

  RegisterResponse _parseRegisterResponse(String body, String username) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final confirmed = json['confirmed'] as bool? ?? false;
      final status = json['status'] as String? ?? 'pending_confirmation';
      return RegisterResponse(
        username: json['username'] as String? ?? username,
        confirmed: confirmed,
        status: status,
      );
    } catch (_) {
      return RegisterResponse(
        username: username,
        confirmed: false,
        status: 'pending_confirmation',
      );
    }
  }

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    _ensureConfigured();
    final response = await http
        .post(
          _uri('/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final confirmed = body['confirmed'] as bool? ?? true;
      if (!confirmed) {
        throw AuthException(
          AuthErrorCode.notConfirmed.defaultMessage,
          code: AuthErrorCode.notConfirmed.name,
        );
      }
      return LoginResponse(
        username: body['username'] as String? ?? username,
        token: body['token'] as String?,
      );
    }

    throw _mapError(response);
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw AuthException(
        '请先在 AuthConfig.apiBaseUrl 中配置认证服务器地址。',
        code: AuthErrorCode.server.name,
      );
    }
  }

  AuthException _mapError(http.Response response) {
    String? code;
    String message = AuthErrorCode.server.defaultMessage;

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      code = body['error'] as String? ?? body['code'] as String?;
      message = body['message'] as String? ?? message;
    } catch (_) {
      // Use status-based fallback.
    }

    code ??= switch (response.statusCode) {
      409 => AuthErrorCode.emailAndUsernameTaken.name,
      403 => AuthErrorCode.notConfirmed.name,
      401 => AuthErrorCode.invalidCredentials.name,
      400 => AuthErrorCode.invalidInput.name,
      _ => AuthErrorCode.server.name,
    };

    if (message == AuthErrorCode.server.defaultMessage) {
      message = _messageForCode(code) ?? message;
    }

    return AuthException(message, code: code);
  }

  String? _messageForCode(String code) {
    for (final value in AuthErrorCode.values) {
      if (value.name == code) {
        return value.defaultMessage;
      }
    }
    return switch (code) {
      'email_taken' => AuthErrorCode.emailTaken.defaultMessage,
      'username_taken' => AuthErrorCode.usernameTaken.defaultMessage,
      'not_confirmed' => AuthErrorCode.notConfirmed.defaultMessage,
      _ => null,
    };
  }
}

class LoginResponse {
  const LoginResponse({required this.username, this.token});

  final String username;
  final String? token;
}
