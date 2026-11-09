import 'package:intl/intl.dart';
import 'package:playx_localization/src/playx_localization.dart';

/// Extension functions to help operations on DateTime.
extension DateExtensions on DateTime {
  /// Converts the date to a formatted string.
  String toFormattedDate(
      {String format = 'dd-MM-yyyy hh:mm a', String? locale}) {
    final df = DateFormat(
        format, locale ?? PlayxLocalization.currentLocale.toLanguageTag());
    return df.format(this);
  }

  /// Converts the date to a formatted time string.
  String toFormattedTime({String format = 'hh:mm a', String? locale}) {
    final df = DateFormat(
        format, locale ?? PlayxLocalization.currentLocale.toLanguageTag());
    return df.format(this);
  }
}
