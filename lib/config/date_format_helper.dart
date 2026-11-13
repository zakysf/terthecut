class IndonesianDateHelper {
  static const List<String> daysShort = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  static const List<String> daysLong = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> monthsLong = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Nama hari pendek (contoh: "Sab")
  static String dayShort(DateTime date) {
    final idx = (date.weekday - 1) % 7;
    return daysShort[idx];
  }

  /// Nama hari panjang (contoh: "Sabtu")
  static String dayLong(DateTime date) {
    final idx = (date.weekday - 1) % 7;
    return daysLong[idx];
  }

  /// Nama bulan pendek (contoh: "Nov")
  static String monthShort(DateTime date) {
    final idx = (date.month - 1) % 12;
    return monthsShort[idx];
  }

  /// Nama bulan panjang (contoh: "November")
  static String monthLong(DateTime date) {
    final idx = (date.month - 1) % 12;
    return monthsLong[idx];
  }

  /// Format tanggal pendek (contoh: "Sabtu, 14 Nov 2026")
  static String formatShort(DateTime date) {
    return '${dayLong(date)}, ${date.day} ${monthShort(date)} ${date.year}';
  }

  /// Format tanggal panjang (contoh: "Sabtu, 14 November 2026")
  static String formatFull(DateTime date) {
    return '${dayLong(date)}, ${date.day} ${monthLong(date)} ${date.year}';
  }

  /// Format jam:menit (contoh: "14:00")
  static String formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Format rentang waktu (contoh: "14:00 - 16:00 WIB")
  static String formatTimeRange(DateTime start, DateTime end) {
    return '${formatTime(start)} - ${formatTime(end)} WIB';
  }
}

