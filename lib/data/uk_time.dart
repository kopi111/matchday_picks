/// football-data.co.uk writes kick-off times in UK wall-clock time (GMT in winter, BST in summer).
/// These helpers turn "26/10/2026" + "20:00" into an exact UTC moment.
library;

/// Parses a UK date ("dd/mm/yyyy" or "dd/mm/yy") and time ("HH:MM") into a UTC [DateTime].
DateTime parseUkKickoff(String dateText, String? timeText) {
  // Split the date into day / month / year; two-digit years mean 20xx.
  final parts = dateText.split('/').map(int.tryParse).toList();
  if (parts.length != 3 || parts.any((part) => part == null)) {
    throw FormatException('Unreadable match date "$dateText"');
  }
  final day = parts[0]!;
  final month = parts[1]!;
  final year = parts[2]! < 100 ? 2000 + parts[2]! : parts[2]!;

  // Missing times are treated as the traditional 15:00 kick-off.
  final time = (timeText == null || timeText.isEmpty ? '15:00' : timeText)
      .split(':');
  final hour = int.tryParse(time[0]) ?? 15;
  final minute = time.length > 1 ? int.tryParse(time[1]) ?? 0 : 0;

  // Treat the wall-clock time as UTC first, then subtract one hour if the UK was on summer time.
  final wallAsUtc = DateTime.utc(year, month, day, hour, minute);
  return _isBritishSummerTime(wallAsUtc.subtract(const Duration(hours: 1)))
      ? wallAsUtc.subtract(const Duration(hours: 1))
      : wallAsUtc;
}

/// True when [utc] falls inside British Summer Time:
/// from 01:00 UTC on the last Sunday of March to 01:00 UTC on the last Sunday of October.
bool _isBritishSummerTime(DateTime utc) {
  final start = _lastSunday(utc.year, 3);
  final end = _lastSunday(utc.year, 10);
  return !utc.isBefore(start) && utc.isBefore(end);
}

/// 01:00 UTC on the last Sunday of [month] in [year].
DateTime _lastSunday(int year, int month) {
  // Day 0 of the next month is the last day of this month; step back to Sunday.
  final lastDay = DateTime.utc(year, month + 1, 0, 1);
  return lastDay.subtract(Duration(days: lastDay.weekday % 7));
}

/// A local calendar-day key like "2026-10-26", used to group matches by day on the phone.
String localDayKey(DateTime moment) {
  final local = moment.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
