import 'package:intl/intl.dart';

class DateHelper {
  static const String defaultDateFormat = 'yyyy-MM-dd';
  static const String defaultDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayDateTimeFormat = 'MMM dd, yyyy HH:mm';

  static String formatDate(DateTime? date, {String format = defaultDateFormat}) {
    if (date == null) return '';
    return DateFormat(format).format(date);
  }

  static String formatDateTime(DateTime dateTime, {String format = defaultDateTimeFormat}) {
    return DateFormat(format).format(dateTime);
  }

  static String formatDisplayDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat(displayDateFormat).format(date);
  }

  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateFormat(defaultDateFormat).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static DateTime? parseDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return null;
    try {
      return DateFormat(defaultDateTimeFormat).parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  static String getDurationString(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '';

    final duration = end.difference(start);
    if (duration.inDays == 0) return '1 day';
    if (duration.inDays == 1) return '2 days';
    return '${duration.inDays + 1} days';
  }

  static String getRelativeTimeString(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(dateTime, format: displayDateFormat);
    }
  }

  static int toUnixTimestamp(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch ~/ 1000;
  }

  static DateTime fromUnixTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }
}
