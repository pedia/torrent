import 'package:flutter/foundation.dart';
import 'package:libtorrent/libtorrent.dart';

import 'base/dimension.dart';

class _WithTime<T> {
  _WithTime(this.t, {DateTime? when}) : when = when ?? DateTime.now();
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
  );

  factory StatsItem.from(StatsAlert statsAlert) {
    // alert_types.hpp:1808
    return StatsItem(
      statsAlert.transferred[0], // upload_payload,
      statsAlert.transferred[1], // upload_protocol,
      statsAlert.transferred[2], // download_payload,
      statsAlert.transferred[3], // download_protocol,
      statsAlert.transferred[4], // upload_ip_protocol,
    );
  }

  final int uploadPayload;
  final int uploadProtocol;
  final int downloadPayload;
  final int downloadProtocol;
  final int uploadIpProtocol;

  @override
  String toString() {
    return '$uploadPayload $uploadProtocol $downloadPayload $downloadProtocol $uploadIpProtocol';
  }
}

/// 存储 SessionStatsAlert 内数值, 提供速率和原始值
class Stats extends ChangeNotifier {
  /// 早期的统计
  final stats = <_WithTime<StatsItem>>[];

  /// 只存储 ...
  final int count = 20;

  int d1 = 0; // stats.protocol download bytes
  int d2 = 0; // session stats.protocol download bytes

  void apply(StatsItem item, {DateTime? when}) {
    stats.add(_WithTime(item, when: when));

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
      var s = 0;
      for (final e in stats.sublist(1)) {
        s += e.t.downloadProtocol;
      }
      final t = stats.last.when.difference(stats.first.when).inMicroseconds;
      return t == 0 ? Dimension.zeroSpeed : Dimension.speed(s * 1e6 ~/ t);
    }
    return Dimension.zeroSpeed;
  }

  /// 长期统计，内容为 List<int>，索引使用 `SessionStatsAlert.findMetricIdx`
  final history = <_WithTime<List<int>>>[];

  /// 3秒推送一次
  void tick(SessionStatsAlert ssa) {
    // Must clone data in the alert
    final vals = List<int>.from(ssa.counters, growable: false);
    history.add(_WithTime(vals));

    d2 = vals[_idxD];

    while (history.length > count) {
      history.removeAt(0);
    }
    notifyListeners();
  }

  /// 下载速度,上传速度
  Dimension get rateOfD => _speedOf(_idxD);
  Dimension get rateOfU => _speedOf(_idxU);

  int get currentD => history.isEmpty ? 0 : history.last.t[_idxD];

  static final int _idxD = SessionStatsAlert.findMetricIndex('net.recv_bytes');
  static final int _idxU = SessionStatsAlert.findMetricIndex('net.sent_bytes');

  Dimension _speedOf(int idx) {
    if (history.isEmpty) {
      return Dimension.zeroSpeed;
    }

    final s = history.last.t[idx] - history.first.t[idx];
    final t = history.last.when.difference(history.first.when).inMilliseconds;

    return t != 0 ? Dimension.speed(s * 1e3 ~/ t) : Dimension.zeroSpeed;
  }
}
