import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('d MMMM yyyy', 'id');
  static final DateFormat _dateFormatEn = DateFormat('d MMMM yyyy', 'en');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dbDateFormat = DateFormat('yyyy-MM-dd');

  static String format(DateTime? date, {String locale = 'id'}) {
    if (date == null) return '-';
    return locale == 'id'
        ? _dateFormat.format(date)
        : _dateFormatEn.format(date);
  }

  static String formatShort(DateTime? date) {
    if (date == null) return '-';
    return _shortDateFormat.format(date);
  }

  static String formatForDb(DateTime date) {
    return _dbDateFormat.format(date);
  }

  static DateTime? parseDbDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return _dbDateFormat.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  static String formatRelative(DateTime date, {String locale = 'id'}) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (locale == 'id') {
      if (difference.inDays == 0) {
        return 'Hari ini';
      } else if (difference.inDays == 1) {
        return 'Kemarin';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari lalu';
      } else {
        return format(date, locale: locale);
      }
    } else {
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return format(date, locale: locale);
      }
    }
  }

  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate);
  }
}
