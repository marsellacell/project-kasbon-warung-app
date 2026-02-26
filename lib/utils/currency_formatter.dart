import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final value = amount is num
        ? amount
        : double.tryParse(amount.toString()) ?? 0;
    return _formatter.format(value);
  }

  static double parse(String value) {
    // Remove currency symbol and dots
    final cleanValue = value.replaceAll('Rp ', '').replaceAll('.', '');
    return double.tryParse(cleanValue) ?? 0;
  }
}
