import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:evi/config/app_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionInfo {
  const VersionInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.updateAvailable,
  });

  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final bool updateAvailable;
}

class VersionService {
  VersionService._();
  static final VersionService instance = VersionService._();

  Future<VersionInfo> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final current = packageInfo.version;

    try {
      final response = await http
          .get(Uri.parse(AppConfig.versionCheckUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final latest = (payload['version'] as String?)?.trim() ?? current;
        final downloadUrl = (payload['url'] as String?)?.trim() ?? '';

        return VersionInfo(
          currentVersion: current,
          latestVersion: latest,
          downloadUrl: downloadUrl,
          updateAvailable: _isNewer(latest, current),
        );
      }
    } catch (_) {
      // Fall through to offline result.
    }

    return VersionInfo(
      currentVersion: current,
      latestVersion: current,
      downloadUrl: '',
      updateAvailable: false,
    );
  }

  /// Returns true when [remote] is greater than [local], e.g. 4.1.0 > 4.0.0.
  static bool _isNewer(String remote, String local) {
    return _compareVersions(remote, local) > 0;
  }

  static int _compareVersions(String a, String b) {
    final partsA = _parseVersionParts(a);
    final partsB = _parseVersionParts(b);
    final length = partsA.length > partsB.length ? partsA.length : partsB.length;

    for (var index = 0; index < length; index++) {
      final valueA = index < partsA.length ? partsA[index] : 0;
      final valueB = index < partsB.length ? partsB[index] : 0;
      if (valueA != valueB) {
        return valueA.compareTo(valueB);
      }
    }
    return 0;
  }

  static List<int> _parseVersionParts(String version) {
    return version
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }
}
