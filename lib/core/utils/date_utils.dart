import 'package:intl/intl.dart';

class AppDateUtils {
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = 'yyyy-MM-ddTHH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayTimeFormat = 'HH:mm';
  static const String displayDateTimeFormat = 'MMM dd, yyyy HH:mm';

  // Formatters
  static final DateFormat _apiDateFormatter = DateFormat(apiDateFormat);
  static final DateFormat _apiDateTimeFormatter = DateFormat(apiDateTimeFormat);
  static final DateFormat _displayDateFormatter = DateFormat(displayDateFormat);
  static final DateFormat _displayTimeFormatter = DateFormat(displayTimeFormat);
  static final DateFormat _displayDateTimeFormatter = DateFormat(displayDateTimeFormat);

  // Format for API
  static String formatForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String formatTimeForApi(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }


  static String formatDateTimeForApi(DateTime dateTime) {
    return _apiDateTimeFormatter.format(dateTime);
  }

  // Format for display
  static String formatForDisplay(DateTime date) {
    return _displayDateFormatter.format(date);
  }

  static String formatTimeForDisplay(DateTime time) {
    return _displayTimeFormatter.format(time);
  }

  static String formatDateTimeForDisplay(DateTime dateTime) {
    return _displayDateTimeFormatter.format(dateTime);
  }

  // Parse from API
  static DateTime parseApiDate(String dateString) {
    return _apiDateFormatter.parse(dateString);
  }

  static DateTime parseApiDateTime(String dateTimeString) {
    return DateTime.parse(dateTimeString); // ISO format
  }

  // Relative time formatting
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formatForDisplay(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Day helpers
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // Smart date formatting
  static String formatSmart(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isTomorrow(date)) {
      return 'Tomorrow';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else if (isThisWeek(date)) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return formatForDisplay(date);
    }
  }

  // Week/Month helpers
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  static DateTime endOfWeek(DateTime date) {
    final daysToSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysToSunday)));
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return endOfDay(nextMonth.subtract(const Duration(days: 1)));
  }

  // Date range helpers
  static List<DateTime> getDaysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = startOfDay(start);
    final endDay = startOfDay(end);

    while (current.isBefore(endDay) || current.isAtSameMomentAs(endDay)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  static List<DateTime> getDaysInWeek(DateTime date) {
    final start = startOfWeek(date);
    return getDaysInRange(start, start.add(const Duration(days: 6)));
  }

  static List<DateTime> getDaysInMonth(DateTime date) {
    final start = startOfMonth(date);
    final end = endOfMonth(date);
    return getDaysInRange(start, end);
  }

  // Time helpers
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  static Duration parseDurationFromMinutes(int minutes) {
    return Duration(minutes: minutes);
  }

  // Validation
  static bool isValidDateString(String dateString) {
    try {
      _apiDateFormatter.parse(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }



  static bool isValidTimeString(String timeString) {
    try {
      _displayTimeFormatter.parse(timeString);
      return true;
    } catch (e) {
      return false;
    }
  }
}