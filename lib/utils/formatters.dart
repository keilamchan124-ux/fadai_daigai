class HkFormatters {
  static String money(double value, {bool showSign = false, int decimals = 1}) {
    final isNegative = value < 0;
    final absVal = value.abs();
    final signPrefix = isNegative ? '-' : (showSign && value > 0 ? '+' : '');

    if (absVal >= 1e16) {
      final numStr = (absVal / 1e16).toStringAsFixed(decimals);
      return '$signPrefix\$${_trimZero(numStr)}京';
    } else if (absVal >= 1e12) {
      final numStr = (absVal / 1e12).toStringAsFixed(decimals);
      return '$signPrefix\$${_trimZero(numStr)}萬億';
    } else if (absVal >= 1e8) {
      final numStr = (absVal / 1e8).toStringAsFixed(decimals);
      return '$signPrefix\$${_trimZero(numStr)}億';
    } else if (absVal >= 1e4) {
      final numStr = (absVal / 1e4).toStringAsFixed(decimals);
      return '$signPrefix\$${_trimZero(numStr)}萬';
    } else if (absVal >= 1000) {
      final intVal = absVal.round();
      final formatted = intVal.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
      return '$signPrefix\$$formatted';
    } else {
      return '$signPrefix\$${absVal.toStringAsFixed(0)}';
    }
  }

  static String compactNumber(double value) {
    final absVal = value.abs();
    if (absVal >= 1e16) {
      return '${_trimZero((value / 1e16).toStringAsFixed(1))}京';
    } else if (absVal >= 1e12) {
      return '${_trimZero((value / 1e12).toStringAsFixed(1))}萬億';
    } else if (absVal >= 1e8) {
      return '${_trimZero((value / 1e8).toStringAsFixed(1))}億';
    } else if (absVal >= 1e4) {
      return '${_trimZero((value / 1e4).toStringAsFixed(1))}萬';
    }
    return value.toStringAsFixed(0);
  }

  static String percent(double value, {bool showSign = true}) {
    final prefix = showSign && value > 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(1)}%';
  }

  static String durationMmSs(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  static String _trimZero(String str) {
    if (str.endsWith('.0')) {
      return str.substring(0, str.length - 2);
    }
    return str;
  }
}
