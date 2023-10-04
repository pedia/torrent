import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libtorrent/libtorrent.dart';
import 'package:path/path.dart';

import 'stats.dart';
import 'task.dart';

export 'package:libtorrent/libtorrent.dart';

/// Top most manager
class SessionController extends ChangeNotifier {
  SessionController._(this.folder, this.sess, this.tasks);

  final String folder;
  final Session sess;
  Timer? ticker;
  final torrents = <int, Torrent>{};
  final stats = Stats();

  /// infohash => Task
  final Map<String, Task> tasks;

  void add(Task task) {
    sess.add(task.params!);

    if (ticker == null) {
      _startTick();
    }
  }

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
    ticker?.cancel();
    save();

    super.dispose();
  }

  int c = 0;

  void tick(_) {
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
        taskByHandle(a.torrentHandle)?.onAdd(a.toAddTorrent());
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
    final fp = join(folder, 'tasks.json');
    File(fp)
        .writeAsString(
          json.encode(tasks.values.map((e) => e.toJson())),
        )
        .then((value) => debugPrint('tasks $fp saved'))
        .onError((err, _) => debugPrint('save $fp failed $err'));

    //
    sess.state.write(join(folder, '.sess'));
    debugPrint('.sess saved');

    //
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

  void _startTick() {
    assert(ticker == null);
    ticker = Timer.periodic(const Duration(seconds: 1), tick);
  }

  /// tasks.json
  /// load resume from id.resume
  ///
  static Future<SessionController> createSession(String folder) async {
    final completer = Completer<SessionController>();

    final p = SessionParams.readFrom(join(folder, '.sess'));
    final sess = Session.create(p);

    unawaited(loadTasks(join(folder, 'tasks.json')).then((tasks) {
      final tm = Map.fromEntries(tasks.map((e) => MapEntry(e.infoHash, e)));
      final sc = SessionController._(folder, sess, tm)..applySetting();

      completer.complete(sc);
    }).catchError((Object e) {
      debugPrint('create session failed $e');
      completer.complete(SessionController._(folder, sess, {}));
    }));

    return completer.future;
  }

  static Future<List<Task>> loadTasks(String fp) async {
    final content = await File(fp).readAsString();
    final ts = json.decode(content) as List;
    return ts.map((e) => Task.fromMap(e as Map<String, String>)).toList();
  }

  void start() {
    // unawaited(File().readAsString().then((content) {
    //   final tasks = (json.decode(content) as List).cast<int>();
    //   for (final n in tasks) {
    //     final p = AddTorrentParams.readFrom(join(folder, '$n.resume'));
    //     debugPrint('load resume file: $n.resume');
    //     if (p != null) {
    //       sess.add(p);
    //     }
    //   }
  }

  Task? taskByHandle(Handle? h) => tasks[h?.infoHash];
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
