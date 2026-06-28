class AuthException implements Exception {
  AuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

enum AuthErrorCode {
  emailTaken,
  usernameTaken,
  emailAndUsernameTaken,
  notConfirmed,
  invalidCredentials,
  invalidInput,
  network,
  server,
}

extension AuthErrorCodeMessage on AuthErrorCode {
  String get defaultMessage => switch (this) {
        AuthErrorCode.emailTaken => '该邮箱已被注册。',
        AuthErrorCode.usernameTaken => '该用户名已被使用。',
        AuthErrorCode.emailAndUsernameTaken => '邮箱和用户名均已被占用。',
        AuthErrorCode.notConfirmed => '账号尚未激活，请查收邮箱并点击激活链接后再登录。',
        AuthErrorCode.invalidCredentials => '用户名或密码错误。',
        AuthErrorCode.invalidInput => '请检查输入信息是否正确。',
        AuthErrorCode.network => '网络连接失败，请稍后重试。',
        AuthErrorCode.server => '服务器错误，请稍后重试。',
      };
}
