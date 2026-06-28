/// App version check configuration.
///
/// Host a JSON file on your server (e.g. Alibaba Cloud OSS), for example:
/// ```json
/// {"version":"4.0.0","url":"https://your-bucket.oss-cn-hangzhou.aliyuncs.com/EVI-4.0.0.apk"}
/// ```
abstract final class AppConfig {
  static const String versionCheckUrl = String.fromEnvironment(
    'VERSION_CHECK_URL',
    defaultValue:
        'https://july161911.oss-cn-shanghai.aliyuncs.com/app_version.json',
  );

  static const String developerEmail = String.fromEnvironment(
    'DEVELOPER_EMAIL',
    defaultValue: 'yiyu.pan@siemens-healthineers.com',
  );
}
