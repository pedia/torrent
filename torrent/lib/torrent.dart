import 'dart:typed_data';
import 'package:torrent/bencode.dart';

/// Helper extension for get String/List from BytesMap.
extension _SafeValue on Map {
  Uint8List? bytesOf(String key) =>
      containsKey(key) ? this[key] as Uint8List : null;

  String? stringOf(String key) =>
      containsKey(key) ? String.fromCharCodes(bytesOf(key)!) : null;

  DateTime? dateOf(String key) => containsKey(key)
      ? DateTime.fromMillisecondsSinceEpoch((this[key] as int) * 1000)
      : null;

  /// List<List<Bytes>> to List<String>
  List<String> expandStringListOf(String key) {
    final res = <String>[];

    if (containsKey(key)) {
      (this[key] as List).cast<List>().forEach((sublist) {
        for (final Uint8List i in sublist) {
          res.add(String.fromCharCodes(i));
        }
      });
    }

    return res;
  }
}

class Torrent {
  final String? name;
  final String? comment;
  final String? createdBy;
  final DateTime? creationDate;
  final String? announce;
  final List<String> announceList;

  final int version;

  Torrent({
    this.version = 0,
    this.name,
    this.comment,
    this.createdBy,
    this.creationDate,
    this.announce,
    this.announceList = const [],
  });

  // {created by: libtorrent, creation date: 1359599503,
  //  info: {length: 0, name: temp, piece length: 16384, pieces: }}

  // info, one file:
  //  length, name, piece length, pieces
  // info multiple files:
  //  piece length
  //  file tree: name => {'':{length, pieces root}}
  //  meta version
  //  name

  // piece layers: {name: hash?}

  // nodes: []

  static parse(Uint8List content) {
    final top = (decodeBytes(content) as Map).cast<Object, Object>();
    print(top.keys);
    return Torrent(
      name: top.stringOf('name'),
      createdBy: top.stringOf('createdBy'),
      comment: top.stringOf('comment'),
      creationDate: top.dateOf('creation date'),
      announce: top.stringOf('announce'),
      announceList: top.expandStringListOf('announce-list'),
      // info: TorrentInfo.from(top['info'] ?? {}),
    );
  }
}
