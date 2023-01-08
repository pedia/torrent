import 'torrent.dart';

class WithTime<T> {
  final T t;
  final DateTime when;
  WithTime(this.t, {DateTime? when}) : when = when ?? DateTime.now();
}

class StatsItem {
  final int uploadPayload;
  final int uploadProtocol;
  final int downloadPayload;
  final int downloadProtocol;
  final int uploadIpProtocol;
  final int downloadIpProtocol;

  StatsItem(
    this.uploadPayload,
    this.uploadProtocol,
    this.downloadPayload,
    this.downloadProtocol,
    this.uploadIpProtocol,
    this.downloadIpProtocol,
  );

  factory StatsItem.from(StatsAlert statsAlert) {
    return StatsItem(
      statsAlert.uploadPayload,
      statsAlert.uploadProtocol,
      statsAlert.downloadPayload,
      statsAlert.downloadProtocol,
      statsAlert.uploadIpProtocol,
      statsAlert.downloadIpProtocol,
    );
  }

  @override
  String toString() {
    return '$uploadPayload $uploadProtocol $downloadPayload $downloadProtocol $uploadIpProtocol $downloadIpProtocol';
  }
}

class Stats {
  final stats = <WithTime<StatsItem>>[];
  final int count = 2;
  final sessionStats = <WithTime<List<int>>>[];

  void apply(StatsItem item, {DateTime? when}) {
    stats.add(WithTime(item, when: when));

    while (stats.length > count) {
      stats.removeAt(0);
    }
  }

  Dimension get speedOfUpload {
    if (stats.isNotEmpty) {
      int s = 0;
      for (var e in stats.sublist(1)) {
        s += e.t.uploadProtocol;
      }
      final t = stats.last.when.difference(stats.first.when).inMicroseconds;
      return t == 0 ? Dimension.zeroSpeed : Dimension.speed(s * 1e6 ~/ t);
    }

    return Dimension.zeroSpeed;
  }

  Dimension get speedOfDownload {
    if (stats.isNotEmpty) {
      int s = 0;
      for (var e in stats.sublist(1)) {
        s += e.t.downloadProtocol;
      }
      final t = stats.last.when.difference(stats.first.when).inMicroseconds;
      return t == 0 ? Dimension.zeroSpeed : Dimension.speed(s * 1e6 ~/ t);
    }
    return Dimension.zeroSpeed;
  }

  void tick(SessionStatsAlert ssa) {
    // Should clone data in alert
    final vals = List<int>.from(ssa.counters);
    sessionStats.add(WithTime(vals));

    while (sessionStats.length > count) {
      sessionStats.removeAt(0);
    }
  }

  static final int idxD = SessionStatsAlert.findMetricIdx('net.recv_bytes');
  static final int idxU = SessionStatsAlert.findMetricIdx('net.sent_bytes');

  Dimension of(int idx) {
    if (sessionStats.isEmpty) {
      return Dimension.zeroSpeed;
    }

    final s = sessionStats.last.t[idx] - sessionStats.first.t[idx];
    final t = sessionStats.last.when
        .difference(sessionStats.first.when)
        .inMicroseconds;

    return t == 0 ? Dimension.zeroSpeed : Dimension.speed(s * 1e6 ~/ t);
  }

  Dimension get rateOfD => of(idxD);
  Dimension get rateOfU => of(idxU);
}

class Dimension {
  factory Dimension.speed(int dim) => Dimension(dim, postfix: '/s');
  factory Dimension.size(int dim) => Dimension(dim);
  factory Dimension.duration(int dim) => DurationDimension(dim);

  static Dimension zeroSpeed = Dimension.speed(0);
  static Dimension zeroSize = Dimension.size(0);

  final int dim;
  final String postfix;
  Dimension(this.dim, {this.postfix = ''});

  static const g = 1024 * 1024 * 1024;
  static const m = 1024 * 1024;
  static const k = 1024;

  @override
  String toString() {
    return '$readable $unit';
  }

  String get unit {
    if (dim > g) {
      return 'GB$postfix';
    } else if (dim > m) {
      return 'MB$postfix';
    } else if (dim > k) {
      return 'KB$postfix';
    }
    return 'B$postfix';
  }

  String get readable {
    if (dim > g) {
      double d = dim / g;
      return d.toStringAsFixed(1);
    } else if (dim > m) {
      double d = dim / m;
      return d.toStringAsFixed(1);
    } else if (dim > k) {
      double d = dim / k;
      return d.toStringAsFixed(0);
    }
    return dim.toString();
  }
}

class DurationDimension extends Dimension {
  DurationDimension(super.dim);

  static const day = 86400;
  static const hour = 3600;
  static const minute = 60;

  @override
  String get unit {
    if (dim > day) {
      return 'day';
    } else if (dim > hour) {
      return 'hour';
    } else if (dim > minute) {
      return 'minute';
    }
    return 'second';
  }

  @override
  String get readable {
    if (dim > day) {
      double d = dim / day;
      return d.toStringAsFixed(1);
    } else if (dim > hour) {
      double d = dim / hour;
      return d.toStringAsFixed(1);
    } else if (dim > minute) {
      double d = dim / minute;
      return d.toStringAsFixed(0);
    }
    return dim.toString();
  }
}
