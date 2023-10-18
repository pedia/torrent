import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libtorrent/libtorrent.dart';
import 'package:path/path.dart';

import 'stats.dart';
import 'task.dart';

// export 'package:libtorrent/libtorrent.dart';

/// Top most manager
class SessionController extends ChangeNotifier {
  SessionController._(this.folder, this.sess, this.tasks);

  final String folder;
  final Session sess;
  Timer? ticker;
  final torrents = <Torrent>[];
  final stats = Stats();

  /// infohash => Task
  final Map<String, Task> tasks;

  /// Add task into session, download beginning
  void add(Task task) {
    if (task.atp != null) {
      // load resume file, if exists
      final fn = '${task.atp?.infoHash}.resume_file';
      var atp = AddTorrentParams.readFrom(fn);

      atp ??= task.atp;
      sess.add(atp!);
    }

    ensureTicker();
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
  bool quit = false;

  void tick(_) {
    // empty alerts queue
    final as = sess.alerts;
    debugPrint('alerts ${as.length}');

    for (var i = 0; i < as.length; i++) {
      final a = as.itemOf(i);
      print(a);

      // necessary action
      if (a is LogAlert) {
          // print(a.logMessage);
        } else if (a is TrackerErrorAlert) {
          // print('  ${a.error} ${a.failureReason}');
        } else if (a is TorrentLogAlert) {
          // print(a.logMessage);
        } else if (a is PeerLogAlert) {
          // print(a.logMessage);
        } else if (a is TorrentLogAlert) {
          // print(a.logMessage);
        } else if (a is TorrentFinishedAlert) {
          a.handle!.saveResumeData();
          quit = true;
          break;
        } else if (a is TorrentErrorAlert) {
          a.handle!.saveResumeData();
          quit = true;
          break;
        } else if (a is SaveResumeDataAlert) {
          final x = a.params.write('${a.params.infoHash}.resume_file');
          print('^^^ .resume_file saved $x');
        } else if (a is SaveResumeDataFailedAlert) {
          quit = true;
          break;
        } else if (a is TorrentResumedAlert) {
          print('torrent_resumed_alert'); // pause -> resumed
        } else if (a is StateChangedAlert) {
          print('state_changed_alert ${a.prevState} => ${a.state}');
          if (a.prevState == TorrentState.downloadingMetadata ||
              a.state == TorrentState.downloading) {
            a.handle?.saveResumeData();
          }
        } else if (a is StateUpdateAlert) {
          print(a.status);
        } else if (a is MetadataReceivedAlert) {
          print('metadata_received_alert ${a.handle}');
          a.handle?.saveResumeData();
        } else if (a is TrackerReplyAlert) {
          print('^^ tracker_reply_alert ${a.trackerUrl} ${a.numPeers}');
        } else if (a is ExternalIpAlert) {
          print('^^ external_ip_alert ${a.externalAddress}');
        } else if (a is PieceFinishedAlert) {
          print('^ piece_finished_alert ${a.pieceIndex}');
        } else if (a is BlockFinishedAlert) {
          // Too many: print('^ block_finished_alert ${a.pieceIndex} ${a.blockIndex}');
        } else if (a is PerformanceAlert) {
          print('^^^ performance_alert ${a.warningCode}');
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
    for (final t in torrents) {
      if (t.handle.needSaveResumeData) {
        t.handle.saveResumeData();
      }
    }
  }

  /// pause/resume
  void toggle() {
    sess.isPaused() ? sess.resume() : sess.pause();
  }

  void ensureTicker() =>
      ticker ??= Timer.periodic(const Duration(seconds: 1), tick);

  /// tasks.json
  /// load resume from id.resume
  ///
  static Future<SessionController> createSession(String folder) async {
    final completer = Completer<SessionController>();

    final p = SessionParams.readFrom(join(folder, '.sess'));

    // ensure setting
    final sp = p.settingsPack;
    sp.setInt(SetName.alertMask, AlertCategory.all);
    sp.setBool(SetName.enableDht, true);
    sp.setBool(SetName.enableUpnp, true);
    sp.setBool(SetName.enableNatpmp, true);

    final sess = Session.create(p);

    unawaited(loadTasks(join(folder, 'tasks.json')).then((tasks) {
      final tm = Map.fromEntries(tasks.map((e) => MapEntry(e.infoHash, e)));
      final sc = SessionController._(folder, sess, tm)..applySetting();

      completer.complete(sc);
    }, onError: (x) {
      completer.complete(SessionController._(folder, sess, {}));
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
