/// Reads football-data.co.uk CSV text into one map per row (header name -> cell text).
///
/// The files are simple: commas, optional double quotes, a byte-order mark on some files.
List<Map<String, String>> parseCsv(String text) {
  // Drop the byte-order mark some files start with, then split into non-blank lines.
  final lines = text
      .replaceFirst('﻿', '')
      .split(RegExp(r'\r?\n'))
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (lines.isEmpty) return [];

  // The first line holds the column names.
  final headers = _splitLine(
    lines.first,
  ).map((header) => header.trim()).toList();

  // Every other line becomes a map keyed by column name; missing cells become ''.
  return lines.skip(1).map((line) {
    final cells = _splitLine(line);
    final row = <String, String>{};
    for (var index = 0; index < headers.length; index++) {
      if (headers[index].isEmpty) continue;
      row[headers[index]] = index < cells.length ? cells[index].trim() : '';
    }
    return row;
  }).toList();
}

/// Splits one CSV line on commas that are not inside double quotes.
List<String> _splitLine(String line) {
  final cells = <String>[];
  final current = StringBuffer();
  var quoted = false;
  for (final character in line.split('')) {
    if (character == '"') {
      // A quote toggles "inside quotes"; commas inside quotes are kept as text.
      quoted = !quoted;
    } else if (character == ',' && !quoted) {
      cells.add(current.toString());
      current.clear();
    } else {
      current.write(character);
    }
  }
  cells.add(current.toString());
  return cells;
}
