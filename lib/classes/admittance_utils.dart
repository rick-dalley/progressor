
import 'dart:math';

import 'package:intl/intl.dart';

class AdmittanceUtils {
  static DateTime generateRandomDoB() {
    final randomYears = Random().nextInt(64 * 365);
    return DateTime.now().subtract(Duration(days: randomYears));
  }

  static DateTime? parseDatabaseDate(String? rawAdmissionDate) {
    if (rawAdmissionDate == null || rawAdmissionDate.isEmpty) return null;

    // 1. Check if it's already a valid ISO string. If so, parse it directly.
    DateTime? parsed = DateTime.tryParse(rawAdmissionDate);
    if (parsed != null) return parsed.toLocal();

    // 2. Handle non-standard "9/1/2025" slashes
    if (rawAdmissionDate.contains('/')) {
      try {
        final parts = rawAdmissionDate.split('/');
        if (parts.length == 3) {
          // Assuming your database structure outputs Month/Day/Year (e.g., "9/1/2025")
          final int month = int.parse(parts[0]);
          final int day = int.parse(parts[1]);
          final int year = int.parse(parts[2]);

          // Construct a clean, native DateTime directly
          return DateTime(year, month, day);
        }
      } catch (_) {
        // Fall through to null if the string contains malformed text
      }
    }

    return null;
  }

  static String formatAdmission(DateTime? dateToFormat){
    DateFormat inputFormat = DateFormat('yyyy MM dd HH:mm');
    String admittedFormatted = "";
    if (dateToFormat != null){
      admittedFormatted = inputFormat.format(dateToFormat);
    }
    return admittedFormatted;

  }
  static String formatDoB(DateTime? dateToFormat){
    DateFormat inputFormat = DateFormat('yyyy MM dd');
    String admittedFormatted = "";
    if (dateToFormat != null){
      admittedFormatted = inputFormat.format(dateToFormat);
    }
    return admittedFormatted;

  }
  /// Generates a random admittance time between 1 and 48 hours ago
  static DateTime generateRandomAdmittance() {
    final randomHours = Random().nextInt(48) + 1;
    return DateTime.now().subtract(Duration(hours: randomHours));
  }

  /// Calculates human-readable string for the toast
  static String getExpiryStatus(DateTime admittedAt) {
    final now = DateTime.now();
    final elapsed = now.difference(admittedAt);
    final remaining = const Duration(hours: 48) - elapsed;

    // Handle case where time might already be expired
    if (remaining.isNegative) return "LEGAL HOLD EXPIRED";

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    return "Admitted: ${admittedAt.hour}:${admittedAt.minute.toString().padLeft(2, '0')}\n"
        "Time Left: ${hours}h ${minutes}m";
  }

  static int calculateYearsSince(DateTime pastDate) {
    final DateTime now = DateTime.now();

    // 1. Get the raw difference in years
    int years = now.year - pastDate.year;

    // 2. Adjust downwards if the anniversary hasn't happened yet this year
    if (now.month < pastDate.month ||
        (now.month == pastDate.month && now.day < pastDate.day)) {
      years--;
    }

    return years;
  }

}

