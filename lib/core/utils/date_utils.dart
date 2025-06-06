import 'package:intl/intl.dart';
import 'package:flutter/material.dart'; // ✅ Para TimeOfDay

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

  // ✅ NUEVO: Método para formatear DateTime para API sin zona horaria
  static String formatDateTimeForApiWithoutZ(DateTime dateTime) {
    final isoString = dateTime.toIso8601String();
    // Remover la 'Z' si está presente para consistencia con el backend
    return isoString.endsWith('Z')
        ? isoString.substring(0, isoString.length - 1)
        : isoString;
  }

  // ✅ ACTUALIZADO: Usar el método sin Z para consistencia
  static String formatDateTimeForApi(DateTime dateTime) {
    return formatDateTimeForApiWithoutZ(dateTime);
  }

  // ✅ NUEVO: Método alternativo usando DateFormat para más control
  static String formatDateTimeForApiCustom(DateTime dateTime) {
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

  // ✅ NUEVO: Parse API DateTime sin zona horaria
  static DateTime parseApiDateTimeWithoutZ(String dateTimeString) {
    // Si no tiene Z, agregar para parsear correctamente
    final normalizedString = dateTimeString.endsWith('Z')
        ? dateTimeString
        : '${dateTimeString}Z';
    return DateTime.parse(normalizedString).toLocal();
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

  // ✅ NUEVO: Helper para crear DateTime con zona horaria local
  static DateTime createLocalDateTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      0, // segundos
      0, // milisegundos
    );
  }

  // ✅ NUEVO: Validar que una fecha sea válida para scheduling
  static bool isValidScheduleDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    // No permitir fechas muy pasadas o muy futuras
    final maxFutureDate = today.add(const Duration(days: 365 * 2)); // 2 años

    return selectedDate.isAtSameMomentAs(today) ||
        (selectedDate.isAfter(today) && selectedDate.isBefore(maxFutureDate));
  }

  // ✅ NUEVO: Validar que una hora sea válida
  static bool isValidScheduleTime(DateTime dateTime) {
    final now = DateTime.now();

    // Si es hoy, la hora debe ser futura
    if (isToday(dateTime)) {
      return dateTime.isAfter(now);
    }

    // Si es fecha futura, cualquier hora es válida
    return dateTime.isAfter(now);
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

  // ✅ NUEVO: Validar formato de fecha ISO
  static bool isValidISODateString(String dateTimeString) {
    try {
      DateTime.parse(dateTimeString);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ✅ NUEVO: Obtener la diferencia en días entre dos fechas
  static int daysBetween(DateTime startDate, DateTime endDate) {
    final start = startOfDay(startDate);
    final end = startOfDay(endDate);
    return end.difference(start).inDays;
  }

  // ✅ NUEVO: Formatear rango de fechas
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return formatForDisplay(startDate);
    }

    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('dd, yyyy').format(endDate)}';
    }

    if (startDate.year == endDate.year) {
      return '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}';
    }

    return '${formatForDisplay(startDate)} - ${formatForDisplay(endDate)}';
  }

  // ✅ NUEVO: Debug helpers para desarrollo
  static void debugPrintDateTime(DateTime dateTime, [String? label]) {
    final prefix = label != null ? '$label: ' : 'DateTime: ';
    print('🔍 $prefix');
    print('  - Local: $dateTime');
    print('  - ISO: ${dateTime.toIso8601String()}');
    print('  - API format: ${formatDateTimeForApiWithoutZ(dateTime)}');
    print('  - Display: ${formatDateTimeForDisplay(dateTime)}');
  }
}