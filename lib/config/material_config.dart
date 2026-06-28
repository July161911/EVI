/// Remote Excel catalog hosted on Alibaba Cloud OSS.
///
/// Replace [excelUrl] with your OSS object URL, for example:
/// `https://your-bucket.oss-cn-hangzhou.aliyuncs.com/materials.xlsx`
///
/// You can also pass `--dart-define=MATERIAL_EXCEL_URL=https://...` at build time.
abstract final class MaterialConfig {
  static const String excelUrl = String.fromEnvironment(
    'MATERIAL_EXCEL_URL',
    defaultValue:
        'https://july161911.oss-cn-shanghai.aliyuncs.com/materials.xlsx',
  );
}
