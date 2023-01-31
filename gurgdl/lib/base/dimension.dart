/// Readable speed/size/duration
class Dimension {
  Dimension(this.val, {this.suffix = ''});

  factory Dimension.speed(int val) => Dimension(val, suffix: '/s');
  factory Dimension.size(int val) => Dimension(val);

  factory Dimension.duration(int val) => _Duration(val);

  static Dimension zeroSpeed = Dimension.speed(0);
  static Dimension zeroSize = Dimension.size(0);

  final int val;
  final String suffix;

  static const g = 1024 * 1024 * 1024;
  static const m = 1024 * 1024;
  static const k = 1024;

  @override
  String toString() {
    return '$readable $unit';
  }

  String get unit {
    if (val > g) {
      return 'GB$suffix';
    } else if (val > m) {
      return 'MB$suffix';
    } else if (val > k) {
      return 'KB$suffix';
    }
    return 'B$suffix';
  }

  String get readable {
    if (val > g) {
      final d = val / g;
      return d.toStringAsFixed(1);
    } else if (val > m) {
      final d = val / m;
      return d.toStringAsFixed(1);
    } else if (val > k) {
      final d = val / k;
      return d.toStringAsFixed(0);
    }
    return val.toString();
  }
}

class _Duration extends Dimension {
  _Duration(super.val);

  static const day = 86400;
  static const hour = 3600;
  static const minute = 60;

  @override
  String get unit {
    if (val > day) {
      return 'day';
    } else if (val > hour) {
      return 'hour';
    } else if (val > minute) {
      return 'minute';
    }
    return 'second';
  }

  @override
  String get readable {
    if (val > day) {
      return (val / day).toStringAsFixed(1);
    } else if (val > hour) {
      return (val / hour).toStringAsFixed(1);
    } else if (val > minute) {
      return (val / minute).toStringAsFixed(0);
    }
    return val.toString();
  }
}
