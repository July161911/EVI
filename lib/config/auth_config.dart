/// Authentication API and email domain configuration.
abstract final class AuthConfig {
  static const String emailDomain = '@siemens-healthineers.com';

  /// Base URL for the registration/login API (no trailing slash).
  /// Expected endpoints: POST /auth/register, /auth/confirm, /auth/login
  static const String apiBaseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
    defaultValue: 'http://121.43.152.209:3000',
  );
  static const String activationWebBaseUrl = 'http://121.43.152.209:3000';

  /// Deep link scheme for email confirmation links, e.g. evi://confirm?token=...
  static const String confirmLinkScheme = 'evi';
  static const String confirmLinkHost = 'confirm';
}
