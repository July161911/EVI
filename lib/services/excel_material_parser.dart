import 'package:excel/excel.dart';
import 'package:evi/models/material_item.dart';

class ExcelMaterialParser {
  ExcelMaterialParser._();

  static const _idHeaders = {'物料号', 'id', 'material id', 'material_id', '编号'};
  static const _nameHeaders = {
    '物料名称',
    'name',
    'material name',
    'material_name',
    '名称',
  };
  static const _locationHeaders = {
    '物料位置',
    'location',
    'material location',
    'material_location',
    '位置',
    '库位',
  };

  static List<MaterialItem> parseBytes(List<int> bytes) {
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      throw FormatException('Excel file contains no worksheets.');
    }

    final sheet = workbook.tables.values.first;
    if (sheet.rows.isEmpty) {
      throw FormatException('Excel worksheet is empty.');
    }

    final rows = sheet.rows;
    final header = _normalizeRow(rows.first);

    final idIndex = _columnIndex(header, _idHeaders);
    final nameIndex = _columnIndex(header, _nameHeaders);
    final locationIndex = _columnIndex(header, _locationHeaders);

    final hasHeader = idIndex != null || nameIndex != null || locationIndex != null;
    final startRow = hasHeader ? 1 : 0;

    final resolvedIdIndex = idIndex ?? 0;
    final resolvedNameIndex = nameIndex ?? 1;
    final resolvedLocationIndex = locationIndex ?? 2;

    final items = <MaterialItem>[];
    for (var rowIndex = startRow; rowIndex < rows.length; rowIndex++) {
      final row = _normalizeRow(rows[rowIndex]);
      if (row.every((cell) => cell.isEmpty)) {
        continue;
      }

      final id = _cellAt(row, resolvedIdIndex);
      final name = _cellAt(row, resolvedNameIndex);
      final location = _cellAt(row, resolvedLocationIndex);
      final deviceId = _cellAt(row, 3);
      final led2 = _cellAt(row, 4);

      if (id.isEmpty && name.isEmpty && location.isEmpty) {
        continue;
      }

      items.add(
        MaterialItem(
          id: id,
          name: name,
          location: location,
          deviceId: deviceId,
          led2: led2,
        ),
      );
    }

    if (items.isEmpty) {
      throw FormatException('No material rows found in Excel file.');
    }

    return items;
  }

  static List<String> _normalizeRow(List<Data?> row) {
    return row.map((cell) => _cellValue(cell).trim()).toList();
  }

  static int? _columnIndex(List<String> header, Set<String> aliases) {
    for (var index = 0; index < header.length; index++) {
      final normalized = header[index].toLowerCase();
      if (aliases.contains(normalized) || aliases.contains(header[index])) {
        return index;
      }
    }
    return null;
  }

  static String _cellAt(List<String> row, int index) {
    if (index < 0 || index >= row.length) {
      return '';
    }
    return row[index];
  }

  static String _cellValue(Data? cell) {
    final value = cell?.value;
    if (value == null) {
      return '';
    }

    return switch (value) {
      TextCellValue() => value.toString().trim(),
      IntCellValue() => value.value.toString(),
      DoubleCellValue() => _formatDouble(value.value),
      DateCellValue() => value.asDateTimeLocal().toIso8601String(),
      DateTimeCellValue() => value.asDateTimeLocal().toIso8601String(),
      TimeCellValue() => value.toString(),
      BoolCellValue() => value.value.toString(),
      FormulaCellValue() => value.formula.trim(),
    };
  }

  static String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
