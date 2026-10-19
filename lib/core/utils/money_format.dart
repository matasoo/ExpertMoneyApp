import 'package:intl/intl.dart';
import 'currency_formatter.dart';

/// Splits an amount into a thousands-separated whole part and 2 decimals,
/// so the UI can render the cents dimmer than the rest ("$24,560" ".40").
class MoneyFormat {
  static final NumberFormat _whole = NumberFormat('#,##0');

  static ({String whole, String decimals}) split(double amount) {
    final fixed = amount.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    return (whole: _whole.format(int.parse(parts[0])), decimals: parts[1]);
  }

  /// Short form for secondary text: "3,108", "1,640.5", "250k" (large values keep the abbreviations).
  static String compact(double amount) {
    if (amount >= 100000) return CurrencyFormatter.format(amount);
    return NumberFormat('#,##0.##').format(amount);
  }

  /// Whole units only ("15,529"), for compact stat pills.
  static String rounded(double amount) {
    if (amount >= 100000) return CurrencyFormatter.format(amount);
    return NumberFormat('#,##0').format(amount.round());
  }

  /// "$" glues to the number ("$24,560"), a code like "RON" gets a space ("RON 24,560").
  static String prefix(String currency) {
    final isSymbol = currency.length <= 1 || !RegExp(r'[A-Za-z]').hasMatch(currency);
    return isSymbol ? currency : '$currency ';
  }
}
