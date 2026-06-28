import 'package:http/http.dart' as http;
import 'package:material_query_app/config/material_config.dart';
import 'package:material_query_app/models/material_item.dart';
import 'package:material_query_app/services/excel_material_parser.dart';

class MaterialService {
  MaterialService._();
  static final MaterialService instance = MaterialService._();

  List<MaterialItem> _catalog = [];
  String? _loadError;

  List<MaterialItem> get catalog => List.unmodifiable(_catalog);
  bool get isLoaded => _catalog.isNotEmpty;
  String? get loadError => _loadError;

  /// Downloads the Excel file from [MaterialConfig.excelUrl] and parses rows
  /// into [MaterialItem]s. Safe to call repeatedly to refresh catalog data.
  Future<void> loadFromExcel({bool forceRefresh = false}) async {
    if (_catalog.isNotEmpty && !forceRefresh) {
      return;
    }

    _loadError = null;
    final url = MaterialConfig.excelUrl.trim();
    if (url.isEmpty ||
        url.contains('your-bucket.oss-cn-hangzhou.aliyuncs.com')) {
      throw MaterialLoadException(
        'Configure MaterialConfig.excelUrl with your Alibaba Cloud OSS Excel URL.',
      );
    }

    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MaterialLoadException(
        'Failed to download Excel file (HTTP ${response.statusCode}).',
      );
    }

    try {
      _catalog = ExcelMaterialParser.parseBytes(response.bodyBytes);
    } on FormatException catch (error) {
      throw MaterialLoadException('Invalid Excel format: ${error.message}');
    } catch (error) {
      throw MaterialLoadException('Failed to parse Excel file: $error');
    }
  }

  List<MaterialItem> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }

    return _catalog
        .where(
          (item) =>
              item.id.toLowerCase().contains(normalized) ||
              item.name.toLowerCase().contains(normalized) ||
              item.location.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  void rememberLoadError(Object error) {
    _loadError = error.toString();
  }
}

class MaterialLoadException implements Exception {
  MaterialLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}
