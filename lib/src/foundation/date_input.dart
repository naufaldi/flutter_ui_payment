import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

List<String> _tokens(String pattern) => pattern.split(RegExp(r'[/ .-]'));
String _separator(String pattern) => pattern.replaceAll(RegExp('[DMY]'), '')[0];
DateTime? parseDateInput(String text, String pattern) {
  final parts = text.split(RegExp(r'[/ .-]'));
  final tokens = _tokens(pattern);
  if (parts.length != 3 || tokens.length != 3) return null;
  final values = <String, int>{};
  for (var i = 0; i < 3; i++) {
    if (!RegExp('^\\d{${tokens[i].length}}\$').hasMatch(parts[i])) return null;
    values[tokens[i]] = int.parse(parts[i]);
  }
  final y = values['YYYY'], m = values['MM'], d = values['DD'];
  if (y == null || m == null || d == null) return null;
  final date = DateTime(y, m, d);
  return date.year == y && date.month == m && date.day == d ? date : null;
}

String formatDateInput(DateTime date, String pattern) => pattern
    .replaceAll('YYYY', date.year.toString().padLeft(4, '0'))
    .replaceAll('MM', date.month.toString().padLeft(2, '0'))
    .replaceAll('DD', date.day.toString().padLeft(2, '0'));
String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime? parseIsoDate(String text) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return null;
  final date = DateTime.tryParse(text);
  return date != null && isoDate(date) == text
      ? DateUtils.dateOnly(date)
      : null;
}

class DateInputFormatter extends TextInputFormatter {
  DateInputFormatter(this.pattern);
  final String pattern;
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final input = digits.substring(0, digits.length.clamp(0, 8));
    final before = newValue.text
        .substring(
          0,
          newValue.selection.extentOffset.clamp(0, newValue.text.length),
        )
        .replaceAll(RegExp(r'\D'), '')
        .length;
    final grew = newValue.text.length > oldValue.text.length;
    final buffer = StringBuffer();
    var index = 0;
    var caret = 0;
    for (final (i, token) in _tokens(pattern).indexed) {
      final count = (input.length - index).clamp(0, token.length);
      buffer.write(input.substring(index, index + count));
      index += count;
      if (i < 2 && count == token.length && (index < input.length || grew)) {
        buffer.write(_separator(pattern));
      }
      if (index <= before) caret = buffer.length;
      if (count < token.length) break;
    }
    // Find the same digit position even when editing inside a group.
    if (before < index) {
      var seen = 0;
      caret = 0;
      for (final c in buffer.toString().split('')) {
        if (RegExp(r'\d').hasMatch(c)) seen++;
        caret++;
        if (seen == before) break;
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: before == 0 ? 0 : caret),
    );
  }
}
