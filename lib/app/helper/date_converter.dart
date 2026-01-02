import 'package:intl/intl.dart';

class DateConverter {
  static String dateTimeStringToFormattedDate(String dateTime) {
    return DateFormat('dd MMM yyyy').format(DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime));
  }

  static String dateTimeStringToTime(String dateTime) {
    return DateFormat('hh:mm a').format(DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime));
  }

  static DateTime dateTimeStringToDate(String dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime);
  }

  static String dateTimeStringToFormattedTime(String dateTime) {
    return DateFormat('dd MMM yyyy hh:mm a').format(DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime).toLocal());
  }

  static DateTime isoUtcStringToLocalTimeOnly(String dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(dateTime, true).toLocal();
  }

  static String isoStringToLocalDateTimeOnly(String dateTime) {
    return DateFormat('dd MMM yyyy HH:mm a').format(isoUtcStringToLocalTimeOnly(dateTime));
  }
}