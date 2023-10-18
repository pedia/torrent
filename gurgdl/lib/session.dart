import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libtorrent/libtorrent.dart';
import 'package:path/path.dart';

import 'stats.dart';
import 'task.dart';

class Counter {
  final map = <dynamic, int>{};

  void add(dynamic key) {
    final c = map[key];
    map[key] = c != null ? c + 1 : 1;
  }

  void dump() {
    final names = <int, String>{
      3: 'torrent_added_alert',
      9: 'performance_alert',
      12: 'tracker_warning_alert',
      15: 'tracker_reply_alert',
      16: 'dht_reply_alert',
      17: 'tracker_announce_alert',
      18: 'hash_failed_alert',
      19: 'peer_ban_alert',
      20: 'peer_unsnubbed_alert',
      21: 'peer_snubbed_alert',
      22: 'peer_error_alert',
      23: 'peer_connect_alert',
      24: 'peer_disconnected_alert',
      25: 'invalid_request_alert',
      27: 'piece_finished_alert',
      28: 'request_dropped_alert',
      29: 'block_timeout_alert',
      30: 'block_finished_alert',
      31: 'block_downloading_alert',
      32: 'unwanted_block_alert',
      42: 'url_seed_alert',
      44: 'metadata_failed_alert',
      45: 'metadata_received_alert',
      46: 'udp_error_alert',
      47: 'external_ip_alert',
      50: 'portmap_error_alert',
      51: 'portmap_alert',
      52: 'portmap_log_alert',
      54: 'peer_blocked_alert',
      55: 'dht_announce_alert',
      56: 'dht_get_peers_alert',
      57: 'stats_alert',
      59: 'anonymous_mode_alert',
      60: 'lsd_peer_alert',
      61: 'trackerid_alert',
      62: 'dht_bootstrap_alert',
      66: 'incoming_connection_alert',
      69: 'mmap_cache_alert',
      73: 'dht_error_alert',
      76: 'dht_put_alert',
      77: 'i2p_alert',
      78: 'dht_outgoing_get_peers_alert',
      79: 'log_alert',
      80: 'torrent_log_alert',
      81: 'peer_log_alert',
      82: 'lsd_error_alert',
      83: 'dht_stats_alert',
      84: 'incoming_request_alert',
      85: 'dht_log_alert',
      86: 'dht_pkt_alert',
      87: 'dht_get_peers_reply_alert',
      89: 'picker_log_alert',
      90: 'session_error_alert',
      91: 'dht_live_nodes_alert',
      92: 'session_stats_header_alert',
      93: 'dht_sample_infohashes_alert',
      94: 'block_uploaded_alert',
      96: 'socks5_alert',
      97: 'file_prio_alert',
      98: 'oversized_file_alert',
      4: 'torrent_removed_alert',
      5: 'read_piece_alert',
      6: 'file_completed_alert',
      7: 'file_renamed_alert',
      8: 'file_rename_failed_alert',
      10: 'state_changed_alert',
      11: 'tracker_error_alert',
      13: 'scrape_reply_alert',
      14: 'scrape_failed_alert',
      26: 'torrent_finished_alert',
      33: 'storage_moved_alert',
      34: 'storage_moved_failed_alert',
      35: 'torrent_deleted_alert',
      36: 'torrent_delete_failed_alert',
      37: 'save_resume_data_alert',
      38: 'save_resume_data_failed_alert',
      39: 'torrent_paused_alert',
      40: 'torrent_resumed_alert',
      41: 'torrent_checked_alert',
      43: 'file_error_alert',
      48: 'listen_failed_alert',
      49: 'listen_succeeded_alert',
      53: 'fastresume_rejected_alert',
      58: 'cache_flushed_alert',
      64: 'torrent_error_alert',
      65: 'torrent_need_cert_alert',
      67: 'add_torrent_alert',
      68: 'state_update_alert',
      70: 'session_stats_alert',
      74: 'dht_immutable_item_alert',
      75: 'dht_mutable_item_alert',
      88: 'dht_direct_response_alert',
      95: 'alerts_dropped_alert',
      99: 'torrent_conflict_alert',
      100: 'peer_info_alert',
      101: 'file_progress_alert',
      102: 'piece_info_alert',
      103: 'piece_availability_alert',
    };

    for (final e in map.entries) {
      if (!names[e.key]!.contains('log')) {
        print('  ${names[e.key]}: ${e.value}');
      }
    }
  }
}

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
  final counter = Counter();

  void tick(_) {
    // empty alerts queue
    final as = sess.alerts;
    debugPrint('alerts ${as.length}');

    c++;
    if (as.length == 0) {
      return;
    }

    for (var i = 0; i < as.length; i++) {
      final a = as.itemOf(i);
      // print(a);

      counter.add(a?.type);

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

    if (c % 10 == 0) {
      counter.dump();
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
    sp.setInt(SetName.alertQueueSize, 15000);
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
