import 'package:intl/intl.dart';

/// Number and date formatting used across the screens.
class Format {
  static final _time = DateFormat('HH:mm');
  static final _day = DateFormat('EEEE d MMMM');
  static final _shortDay = DateFormat('EEE d');

  /// "67%"
  static String percent(double value) => '${(value * 100).round()}%';

  /// "+3.6%" / "−2.7%"
  static String signedPercent(double value) =>
      '${value >= 0 ? '+' : '−'}${(value.abs() * 100).toStringAsFixed(1)}%';

  /// "$30.00" / "−$12.40"
  static String money(double value) =>
      '${value < 0 ? '−' : ''}\$${value.abs().toStringAsFixed(2)}';

  /// "1.50" or "n/a"
  static String odds(double? value) =>
      value == null ? 'n/a' : value.toStringAsFixed(2);

  /// Local kick-off time "13:30".
  static String time(DateTime moment) => _time.format(moment.toLocal());

  /// "Monday 26 October"
  static String day(DateTime moment) => _day.format(moment.toLocal());

  /// "Mon 26"
  static String shortDay(DateTime moment) => _shortDay.format(moment.toLocal());
}
