import 'dart:io';

import 'package:libtorrent/libtorrent.dart';

import 'base/enum_utils.dart';

enum TaskType {
  torrent,
  magnet,
  ed2k,
}

/// store path
const storePath = 'store';

/// Generic Download task
///
/// Store session in
/// - .sess file
/// - tasks.json
///
/// A task has magnet
///   / torrent file / storage path
///   name
///
class Task {
  Task._({
    required this.type,
    required this.source,
    required this.infoHash,
    this.name,
    this.atp,
  });

  factory Task.fromMap(Map<String, dynamic> map) => Task._(
        source: map['source'] as String,
        type: EnumUtils<TaskType>(TaskType.values)
            .enumEntry(map['type'] as String)!,
        name: map['name'] as String?,
        infoHash: map['infoHash'] as String,
      );

  final String infoHash;
  final String source;
  final TaskType type;
  final AddTorrentParams? atp;
  String? name;
  Handle? handle;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'source': source,
        'name': name,
        'infoHash': infoHash,
      };

  static Task? fromTorrent(File fp) {
    return null;
  }

  static Task? fromUri(String uri) {
    final atp = AddTorrentParams.parseMagnet(uri, storePath);
    if (atp != null) {
      return Task._(
        source: uri,
        type: TaskType.magnet,
        infoHash: atp.infoHash,
        atp: atp,
      );
    }
    return null;
  }

  /// when this task added into session
  void onAdd(AddTorrentAlert? alert) {}
}
