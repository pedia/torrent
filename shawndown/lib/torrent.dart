import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:libtorrent/libtorrent.dart';
import 'package:path/path.dart';
import 'package:scoped_model/scoped_model.dart';

import 'stats.dart';

export 'package:libtorrent/libtorrent.dart';

/// top most manager
class SessionController extends Model {
  static SessionController? _instance;
  final String folder;
  final Session sess;
  late Timer ticker;
  final torrents = <int, Torrent>{};

  final stats = Stats();

  SessionController._(this.folder, this.sess);

  void applySetting() {
    final p = sess.settingsPack;
    final o = p.getInt(SetName.alertMask);
    p.setInt(
      SetName.alertMask,
      o |
          // AlertCategory.connect |
          AlertCategory.blockProgress |
          AlertCategory.tracker |
          AlertCategory.performanceWarning |
          AlertCategory.dhtOperation |
          AlertCategory.fileProgress |
          // AlertCategory.dht |
          AlertCategory.stats |
          // AlertCategory.sessionLog |
          // AlertCategory.torrentLog |
          // too much: AlertCategory.dhtLog |
          AlertCategory.portMappingLog |
          AlertCategory.status,
    );
    sess.apply(p);
  }

  void dispose() {
    ticker.cancel();
    save();
  }

  void handle(_) {
    // empty alerts queue
    final as = sess.alerts;
    // debugPrint('alerts ${as.length}');

    for (int i = 0; i < as.length; i++) {
      final a = as.itemOf(i);

      if (a.type == SaveResumeDataAlert.type) {
        final srd = a.cast() as SaveResumeDataAlert;
        final fp = '${a.torrentHandle!.id}.resume';
        debugPrint('torrent resume data write to $fp');
        srd.params.write(join(folder, fp));
      } else if (a.type == SessionStatsAlert.type) {
        stats.tick(a.toSessionStats() as SessionStatsAlert);
      } else if (a.type == StatsAlert.type) {
        stats.apply(StatsItem.from(a.toStats() as StatsAlert));
      }

      // TODO: handle torrent added alert
      final h = a.torrentHandle;
      if (h != null) {
        torrents[h.id] = Torrent(h, sizes: <int>[]);

        notifyListeners();
      }
      // debugPrint(a.toString());
    }

    // Notify session to alerts next session-stats
    sess.postStats();
  }

  void save() {
    sess.state.write(join(folder, '.sess'));
    debugPrint('.sess saved');

    File(join(folder, 'tasks.json'))
        .writeAsString(
          json.encode(torrents.entries.map((e) => e.value.handle.id).toList()),
        )
        .then((value) => debugPrint('tasks.json saved'))
        .onError((err, _) => debugPrint('save tasks.json failed $err'));

    torrents.forEach((id, t) {
      t.handle.saveResumeData();
    });
  }

  /// pause/resume
  void toggle() {
    sess.isPaused() ? sess.resume() : sess.pause();
  }

  void _init() {
    applySetting();

    ticker = Timer.periodic(const Duration(seconds: 1), handle);
  }

  /// tasks.json
  /// load resume from {torrent name}.resume
  ///
  static Future<SessionController> createSession(String folder) async {
    if (_instance != null) {
      return _instance!;
    }

    final completer = Completer<SessionController>();

    final p = SessionParams.readFrom(join(folder, '.sess'));
    final sess = Session.create(p);

    _instance = SessionController._(folder, sess);

    _instance!._init();

    File(join(folder, 'tasks.json')).readAsString().then((content) {
      final tasks = json.decode(content) as List;
      for (int n in tasks) {
        final p = AddTorrentParams.readFrom(join(folder, '$n.resume'));
        debugPrint('load resume file: $n.resume');
        if (p != null) {
          sess.add(p);
        }
      }

      completer.complete(_instance);
    }).catchError((e) {
      debugPrint('create session failed $e');
      completer.complete(_instance);
    });

    return completer.future;
  }
}

class Torrent extends Model {
  final Handle handle;
  final List<int> sizes;
  bool metadata = false;

  Torrent(this.handle, {this.sizes = const <int>[]});

  void queryFileSize() {
    sizes.clear();
    sizes.addAll(handle.fileProgress);
  }
}
