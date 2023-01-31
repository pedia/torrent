import 'package:flutter/foundation.dart';
import 'package:libtorrent/libtorrent.dart';

import 'base/dimension.dart';

class WithTime<T> {
  WithTime(this.t, {DateTime? when}) : when = when ?? DateTime.now();
  final T t;
  final DateTime when;
}

class StatsItem {
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

  final int uploadPayload;
  final int uploadProtocol;
  final int downloadPayload;
  final int downloadProtocol;
  final int uploadIpProtocol;
  final int downloadIpProtocol;

  @override
  String toString() {
    return '$uploadPayload $uploadProtocol $downloadPayload $downloadProtocol $uploadIpProtocol $downloadIpProtocol';
  }
}

class Stats extends ChangeNotifier {
  final stats = <WithTime<StatsItem>>[];
  final int count = 20;
  final sessionStats = <WithTime<List<int>>>[];

  int d1 = 0; // stats.protocol download bytes
  int d2 = 0; // session stats.protocol download bytes

  void apply(StatsItem item, {DateTime? when}) {
    stats.add(WithTime(item, when: when));

    print(item);
    d1 += item.downloadProtocol;

    while (stats.length > count) {
      stats.removeAt(0);
    }
    notifyListeners();
  }

  Dimension get speedOfUpload {
    if (stats.isNotEmpty) {
      var s = 0;
      for (final e in stats.sublist(1)) {
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
    // Must clone data in the alert
    final vals = List<int>.from(ssa.counters);
    sessionStats.add(WithTime(vals));

    d2 = vals[idxD];

    while (sessionStats.length > count) {
      sessionStats.removeAt(0);
    }
    notifyListeners();
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

  int get currentD => sessionStats.isEmpty ? 0 : sessionStats.last.t[idxD];
}
