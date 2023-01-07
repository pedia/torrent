import 'package:libtorrent/libtorrent.dart';

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
  final int count = 100;
  final sessionStats = <WithTime<List<int>>>[];

  void apply(StatsItem item, {DateTime? when}) {
    stats.add(WithTime(item, when: when));

    if (stats.length > count) {
      stats.removeAt(0);
    }
  }

  Speed get speedOfUpload {
    if (stats.isNotEmpty) {
      int s = 0;
      for (var e in stats.sublist(1)) {
        s += e.t.uploadProtocol;
      }
      final t = stats.last.when.difference(stats.first.when).inMicroseconds;
      return t == 0 ? Speed(0) : Speed(s * 1e6 ~/ t);
    }

    return Speed.zero;
  }

  Speed get speedOfDownload {
    if (stats.isNotEmpty) {
      int s = 0;
      for (var e in stats.sublist(1)) {
        s += e.t.downloadProtocol;
      }
      final t = stats.last.when.difference(stats.first.when).inMicroseconds;
      return t == 0 ? Speed(0) : Speed(s * 1e6 ~/ t);
    }
    return Speed.zero;
  }

  void tick(SessionStatsAlert ssa) {
    // Should clone data in alert
    final vals = List<int>.from(ssa.counters);
    sessionStats.add(WithTime(vals));

    if (sessionStats.length > count) {
      sessionStats.removeAt(0);
    }
  }

  static final int idxD = SessionStatsAlert.findMetricIdx('net.recv_bytes');
  static final int idxU = SessionStatsAlert.findMetricIdx('net.sent_bytes');

  Speed of(int idx) {
    if (sessionStats.isEmpty) {
      return Speed.zero;
    }
    
    final s = sessionStats.last.t[idx] - sessionStats.first.t[idx];
    final t = sessionStats.last.when
        .difference(sessionStats.first.when)
        .inMicroseconds;

    return t == 0 ? Speed(0) : Speed(s * 1e6 ~/ t);
  }

  Speed get rateOfD => of(idxD);
  Speed get rateOfU => of(idxU);
}

class Speed {
  final int speed;
  Speed(this.speed);

  static Speed zero = Speed(0);

  static const g = 1024 * 1024 * 1024;
  static const m = 1024 * 1024;
  static const k = 1024;

  @override
  String toString() {
    return '$readable $unit';
  }

  String get unit {
    if (speed > g) {
      return 'GB/s';
    } else if (speed > m) {
      return 'MB/s';
    } else if (speed > k) {
      return 'KB/s';
    }
    return 'B/s';
  }

  String get readable {
    if (speed > g) {
      double d = speed / g;
      return d.toStringAsFixed(1);
    } else if (speed > m) {
      double d = speed / m;
      return d.toStringAsFixed(1);
    } else if (speed > k) {
      double d = speed / k;
      return d.toStringAsFixed(0);
    }
    return speed.toString();
  }
}
