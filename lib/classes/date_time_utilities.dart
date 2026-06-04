class DTUtilities {
  static int dateStringToUnixInt(String dateString) {
    try {
      // 1. Try standard ISO parsing first
      return DateTime
          .parse(dateString)
          .millisecondsSinceEpoch ~/ 1000;
    } catch (e) {
      // 2. Fallback: Split "2/8/2026" by "/"
      List<String> parts = dateString.split('/');
      if (parts.length == 3) {
        int month = int.parse(parts[0]);
        int day = int.parse(parts[1]);
        int year = int.parse(parts[2]);

        return DateTime(year, month, day).millisecondsSinceEpoch ~/ 1000;
      }
      // 3. Last resort: Return current time if all else fails
      return DateTime
          .now()
          .millisecondsSinceEpoch ~/ 1000;
    }
  }

  static DateTime aYearAgo(){
    DateTime now = DateTime.timestamp();

// 2. Subtract 1 from the year (handles leap years correctly)
    DateTime oneYearAgo = DateTime(
        now.year - 1,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
        now.millisecond
    );
    return oneYearAgo;
  }
  static int aYearAgoAsUnixInt() {
    // 1. Get the current UTC timestamp as a DateTime


// 3. Convert to Unix timestamp (seconds)
    return aYearAgo().millisecondsSinceEpoch ~/ 1000;
  }

  static DateTime aWhileAgo(int m){
    DateTime now = DateTime.timestamp();

// 2. Subtract 1 from the year (handles leap years correctly)
    DateTime aWhileAgo = DateTime(
        now.year,
        now.month-m,
        now.day,
        now.hour,
        now.minute,
        now.second,
        now.millisecond
    );
    return aWhileAgo;
  }

  static int aWhileAgoUnixInt(int m) {
    return aWhileAgo(m).millisecondsSinceEpoch ~/ 1000;
  }


  static DateTime aMonthAgo(){
    DateTime now = DateTime.timestamp();
    // Subtract 1 from the month (handles leap years correctly)
    DateTime aMonthAgo = DateTime(
        now.year,
        now.month - 1,
        now.day,
        now.hour,
        now.minute,
        now.second,
        now.millisecond
    );
    return aMonthAgo;
  }

  static int aMonthAgoUnixInt(){
    return aMonthAgo().millisecondsSinceEpoch ~/ 1000;
  }

  static DateTime aWeekAgo(){
    DateTime now = DateTime.timestamp();
    // Subtract 1 from the month (handles leap years correctly)
    DateTime aWeekAgo = DateTime(
        now.year,
        now.month,
        now.day - 7,
        now.hour,
        now.minute,
        now.second,
        now.millisecond
    );
    return aWeekAgo;
  }

  static int aWeekAgoUnixInt(){
    return aWeekAgo().millisecondsSinceEpoch ~/ 1000;
  }

  static DateTime yesterday(){
    DateTime now = DateTime.timestamp();
    // Subtract 1 from the month (handles leap years correctly)
    DateTime yesterday = DateTime(
        now.year,
        now.month,
        now.day - 1,
        now.hour,
        now.minute,
        now.second,
        now.millisecond
    );
    return yesterday;
  }

  static int yesterdayUnixInt(){
    return yesterday().millisecondsSinceEpoch ~/ 1000;
  }

}
