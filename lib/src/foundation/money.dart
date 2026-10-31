import 'package:flutter/foundation.dart';

/// Currency metadata used for formatting and parsing.
///
/// The package ships a small registry; hosts can register more with
/// [CurrencySpec.register] before formatting amounts in that currency.
@immutable
class CurrencySpec {
  const CurrencySpec({
    required this.code,
    required this.symbol,
    required this.minorDigits,
  });

  final String code;
  final String symbol;

  /// Number of decimal digits stored in minor units (IDR = 0, USD = 2).
  final int minorDigits;

  static final Map<String, CurrencySpec> _registry = {
    'IDR': const CurrencySpec(code: 'IDR', symbol: 'Rp', minorDigits: 0),
    'USD': const CurrencySpec(code: 'USD', symbol: r'$', minorDigits: 2),
    'SGD': const CurrencySpec(code: 'SGD', symbol: r'S$', minorDigits: 2),
  };

  static void register(CurrencySpec spec) => _registry[spec.code] = spec;

  static CurrencySpec of(String code) =>
      _registry[code] ?? CurrencySpec(code: code, symbol: code, minorDigits: 2);
}

/// An amount of money as an integer number of minor units.
///
/// Arithmetic never uses floating point, and mixing currencies throws.
@immutable
class Money implements Comparable<Money> {
  const Money(this.minorUnits, this.currency);

  /// Indonesian rupiah; IDR has no minor digits.
  const Money.idr(int rupiah) : this(rupiah, 'IDR');

  const Money.zero(String currency) : this(0, currency);

  final int minorUnits;
  final String currency;

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;

  Money operator +(Money other) {
    _checkCurrency(other);
    return Money(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _checkCurrency(other);
    return Money(minorUnits - other.minorUnits, currency);
  }

  Money operator -() => Money(-minorUnits, currency);

  bool operator >(Money other) => compareTo(other) > 0;
  bool operator <(Money other) => compareTo(other) < 0;
  bool operator >=(Money other) => compareTo(other) >= 0;
  bool operator <=(Money other) => compareTo(other) <= 0;

  @override
  int compareTo(Money other) {
    _checkCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  void _checkCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Cannot combine $currency with ${other.currency} amounts.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => 'Money($minorUnits $currency)';
}

/// Locale-aware formatting and strict parsing of [Money].
///
/// Only the separators differ between supported locales: `id` groups with
/// `.` and uses `,` for decimals, `en` does the opposite.
@immutable
class MoneyFormat {
  const MoneyFormat(this.languageCode);

  final String languageCode;

  bool get _isId => languageCode == 'id';
  String get groupSeparator => _isId ? '.' : ',';
  String get decimalSeparator => _isId ? ',' : '.';

  String format(Money money, {bool withSymbol = true}) {
    final spec = CurrencySpec.of(money.currency);
    final negative = money.isNegative;
    final abs = money.minorUnits.abs();
    final digits = spec.minorDigits;
    var divisor = 1;
    for (var i = 0; i < digits; i++) {
      divisor *= 10;
    }
    final major = abs ~/ divisor;
    final minor = abs % divisor;
    final buffer = StringBuffer();
    if (negative) buffer.write('−');
    if (withSymbol) buffer.write(spec.symbol);
    buffer.write(_group(major.toString()));
    if (digits > 0) {
      buffer
        ..write(decimalSeparator)
        ..write(minor.toString().padLeft(digits, '0'));
    }
    return buffer.toString();
  }

  /// Plain digits for screen readers, e.g. "100000 IDR".
  String spoken(Money money) {
    final text = format(
      money,
      withSymbol: false,
    ).replaceAll(groupSeparator, '').replaceAll('−', '-');
    return '$text ${money.currency}';
  }

  String _group(String digits) {
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      out.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) out.write(groupSeparator);
    }
    return out.toString();
  }

  /// Parses typed or pasted text into [Money].
  ///
  /// Accepts the currency symbol/code, spaces and correctly placed group
  /// separators. Anything that could be read two ways (for example `100,000`
  /// for IDR under `id`) is rejected as [AmountIssue.ambiguous] instead of
  /// being guessed.
  AmountParseResult parse(String input, String currency) {
    final spec = CurrencySpec.of(currency);
    var text = input.trim();
    if (text.isEmpty) return const AmountParseResult.issue(AmountIssue.empty);
    text = text
        .replaceAll(spec.symbol, '')
        .replaceAll(spec.code, '')
        .replaceAll(RegExp(r'[\s ]'), '');
    var negative = false;
    if (text.startsWith('-') || text.startsWith('−')) {
      negative = true;
      text = text.substring(1);
    }
    if (text.isEmpty) return const AmountParseResult.issue(AmountIssue.empty);
    if (!RegExp(r'^[0-9.,]+$').hasMatch(text)) {
      return const AmountParseResult.issue(AmountIssue.invalidFormat);
    }

    String integerPart = text;
    String fractionPart = '';
    final decimalIndex = text.lastIndexOf(decimalSeparator);
    if (decimalIndex >= 0) {
      integerPart = text.substring(0, decimalIndex);
      fractionPart = text.substring(decimalIndex + 1);
      if (fractionPart.contains(groupSeparator) ||
          integerPart.contains(decimalSeparator)) {
        return const AmountParseResult.issue(AmountIssue.ambiguous);
      }
      if (spec.minorDigits == 0 || fractionPart.length > spec.minorDigits) {
        // "100,000" for IDR in `id`: decimals are impossible, so the user
        // probably meant a group separator from another locale.
        return const AmountParseResult.issue(AmountIssue.ambiguous);
      }
      if (fractionPart.isEmpty) {
        return const AmountParseResult.issue(AmountIssue.invalidFormat);
      }
    }
    if (integerPart.isEmpty) {
      return const AmountParseResult.issue(AmountIssue.invalidFormat);
    }
    if (integerPart.contains(groupSeparator)) {
      final groups = integerPart.split(groupSeparator);
      final validGroups =
          groups.first.isNotEmpty &&
          groups.first.length <= 3 &&
          groups.skip(1).every((g) => g.length == 3);
      if (!validGroups) {
        return const AmountParseResult.issue(AmountIssue.ambiguous);
      }
      integerPart = groups.join();
    }
    if (integerPart.length > 15) {
      return const AmountParseResult.issue(AmountIssue.aboveMaximum);
    }
    var minor = int.parse(integerPart);
    for (var i = 0; i < spec.minorDigits; i++) {
      minor *= 10;
    }
    if (fractionPart.isNotEmpty) {
      minor += int.parse(fractionPart.padRight(spec.minorDigits, '0'));
    }
    if (negative && minor != 0) {
      return const AmountParseResult.issue(AmountIssue.negative);
    }
    return AmountParseResult.value(Money(minor, currency));
  }
}

enum AmountIssue {
  empty,
  invalidFormat,
  ambiguous,
  negative,
  zero,
  belowMinimum,
  aboveMaximum,
}

/// Outcome of parsing and validating an amount. Exactly one of [money] or
/// [issue] is set.
@immutable
class AmountParseResult {
  const AmountParseResult.value(Money this.money) : issue = null;
  const AmountParseResult.issue(AmountIssue this.issue) : money = null;

  final Money? money;
  final AmountIssue? issue;

  bool get isValid => money != null;

  /// Applies host-supplied limits to a successfully parsed amount.
  AmountParseResult withinLimits({Money? minimum, Money? maximum}) {
    final value = money;
    if (value == null) return this;
    if (value.isZero) return const AmountParseResult.issue(AmountIssue.zero);
    if (minimum != null && value < minimum) {
      return const AmountParseResult.issue(AmountIssue.belowMinimum);
    }
    if (maximum != null && value > maximum) {
      return const AmountParseResult.issue(AmountIssue.aboveMaximum);
    }
    return this;
  }

  @override
  bool operator ==(Object other) =>
      other is AmountParseResult &&
      other.money == money &&
      other.issue == issue;

  @override
  int get hashCode => Object.hash(money, issue);

  @override
  String toString() => isValid ? 'Parsed($money)' : 'Issue($issue)';
}
