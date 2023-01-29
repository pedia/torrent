import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libtorrent/libtorrent.dart';
import 'package:path/path.dart';

import 'stats.dart';

export 'package:libtorrent/libtorrent.dart';

/// Top most manager
class SessionController extends ChangeNotifier {
  SessionController._(this.folder, this.sess);

  static SessionController? _instance;

  final String folder;
  final Session sess;
  late Timer ticker;
  final torrents = <int, Torrent>{};
  final stats = Stats();

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

  @override
  void dispose() {
    ticker.cancel();
    save();

    super.dispose();
  }

  int c = 0;

  void handle(_) {
    // empty alerts queue
    final as = sess.alerts;
    debugPrint('alerts ${as.length}');

    for (var i = 0; i < as.length; i++) {
      final a = as.itemOf(i);

      if (a.type == SaveResumeDataAlert.type) {
        final srd = a.cast()! as SaveResumeDataAlert;
        final fp = '${a.torrentHandle!.id}.resume';
        debugPrint('torrent resume data write to $fp');
        srd.params.write(join(folder, fp));
      } else if (a.type == SessionStatsAlert.type) {
        stats.tick(a.toSessionStats()!);
      } else if (a.type == StatsAlert.type) {
        final sa = a.toStats();
        stats.apply(StatsItem.from(sa!));
      } else if (a.type == AddTorrentAlert.type) {
        final h = a.torrentHandle;
        if (h != null) {
          final ata = a.toAddTorrent();
          if (ata != null) {
            print('TODO: AddTorrent.error ${ata.error}');

            torrents[h.id] = Torrent(h, ata.params, sizes: <int>[]);

            notifyListeners();
          } else {}
        }
      }

      if (c++ < 20) {
        print(a);
      }
    }

    // Notify session to alerts next session-stats
    // sess.postStats();
    // print('post ${DateTime.now()}');
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
      if (t.handle.needSaveResumeData) {
        t.handle.saveResumeData();
      }
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
  /// load resume from id.resume
  ///
  static Future<SessionController> createSession(String folder) async {
    if (_instance != null) {
      return _instance!;
    }

    final completer = Completer<SessionController>();

    final p = SessionParams.readFrom(join(folder, '.sess'));
    final sess = Session.create(p);

    _instance = SessionController._(folder, sess);

    _instance?._init();

    unawaited(File(join(folder, 'tasks.json')).readAsString().then((content) {
      final tasks = (json.decode(content) as List).cast<int>();
      for (final n in tasks) {
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
    }));

    return completer.future;
  }
}

class Torrent extends ChangeNotifier {
  Torrent(this.handle, this.params, {this.sizes = const <int>[]});

  final Handle handle;
  final AddTorrentParams params;
  final List<int> sizes;
  bool metadata = false;

  void queryFileSize() {
    sizes.clear();
    sizes.addAll(handle.fileProgress);
  }
}
