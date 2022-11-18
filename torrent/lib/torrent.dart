import 'dart:typed_data';
import 'package:crypto/crypto.dart' show Digest;

import 'package:torrent/bencode.dart';
import 'package:torrent/src/file_storage.dart';
import 'package:torrent/src/url_utils.dart';

import 'error.dart';
import 'magnet.dart';

///
int? _castInt(Object? v) {
  return v is int ? v : null;
}

DateTime? _castDate(Object? v) {
  if (v is int) {
    return DateTime.fromMillisecondsSinceEpoch(v * 1000);
  }
  return null;
}

String? _castString(Object? v) {
  if (v is Uint8List) {
    return String.fromCharCodes(v);
  }
  return null;
}

/// List<List<Uint8List>> to List<String>
List<String> _castByteStringList(Object? v) {
  final res = <String>[];
  if (v is List) {
    for (var el in v) {
      if (el is List) {
        for (var e in el) {
          if (e is Uint8List) {
            res.add(String.fromCharCodes(e));
          }
        }
      }
    }
  }
  return res;
}

/// List<Uint8List>
List<String>? _castStringList(Object? v) {
  if (v is List) {
    return v.map((e) => String.fromCharCodes(e as Uint8List)).toList();
  }
  return null;
}

///
class Torrent {
  final String? name;
  final String? comment;
  final String? createdBy;
  final DateTime? ctime;
  final List<String> announces;
  final List<String> webseeds;

  final int version;

  final FileStorage? storage;

  Torrent({
    this.version = 0,
    this.name,
    this.comment,
    this.createdBy,
    this.ctime,
    List<String>? announces,
    List<String>? webseeds,
    this.storage,
  })  : announces = announces ?? [],
        webseeds = webseeds ?? [];

  List<File>? get files => storage?.files;

  @override
  String toString() => 'Torrent($name)';

  static Torrent? parse(Uint8List content) {
    final map = decodeBytes(content);
    if (map is! Map || map.isEmpty) {
      throw TorrentError(ErrorCode.torrentIsNoDict);
    }

    final top = map.cast<String, Object>();

    final info = top['info'];
    if (info == null) {
      final uri = _castString(top['magnet-uri']);
      if (uri != null) {
        final p = Magnet.parse(uri);
        // infoHash
        // urls
        return null;
      }

      throw TorrentError(ErrorCode.torrentMissingInfo);
    }

    // parse info section
    if (info is! Map) {
      throw TorrentError(ErrorCode.torrentInfoNoDict);
    }

    // TODO: info-hash

    // version
    final version = _castInt(info['meta version']) ?? 1;
    if (version > 2) {
      throw TorrentError(ErrorCode.torrentUnknownVersion);
    }

    // piece length
    final pieceLength = _castInt(info['piece length']);
    if (pieceLength == null ||
        pieceLength <= 0 ||
        pieceLength > 0x7fffffff / 2) {
      throw TorrentError(ErrorCode.torrentMissingPieceLength);
    }

    // according to BEP 52: "It must be a power of two and at least 16KiB."
    if (version > 1 &&
        (pieceLength < 16 * 1024 || (pieceLength & (pieceLength - 1)) != 0)) {
      throw TorrentError(ErrorCode.torrentMissingPieceLength);
    }

    // name
    final name = _castString(info['name.utf-8']) ?? _castString(info['name']);
    if (name == null || name.isEmpty) {
      throw TorrentError(ErrorCode.torrentMissingName);
    }

    final path = sanitizePath(name);
    if (path.isEmpty) {
      throw TorrentError(ErrorCode.torrentMissingName);
    }

    // storage
    final storage = FileStorage(
      pieceLenth: pieceLength,
      name: path, // sanitize name as path
    );

    final pieces = info['pieces'];
    if (pieces == null) {
      throw TorrentError(ErrorCode.torrentMissingPieces);
    }

    final fileTree = info['file tree'];
    final files = info['files'];

    if (version >= 2 && fileTree != null) {
      storage.buildV2(fileTree, info);
    } else if (files != null) {
      storage.buildV1(files, pieces);
    } else {
      final length = info['length'];

      storage.buildSingleFile(
          length: length, mtime: _castInt(info['mtime']), pieces: pieces);
    }

    // throw TorrentError(ErrorCode.torrentMissingFileTree);

    // http seeds
    final webseeds = _castByteStringList(top['url-list']);
    final s2 = _castStringList(top['httpseeds']);
    if (s2 != null) {
      webseeds.addAll(s2);
    }

    // TODO: trim, filter empty

    //
    final announce = _castByteStringList(top['announce-list']);

    String? url = sanitizeUrl(_castString(top['announce']));
    if (url != null && url.isNotEmpty) {
      announce.insert(0, url);
    }

    return Torrent(
      name: name,
      createdBy: _castString(top['created by.utf-8']) ??
          _castString(top['created by']),
      comment: _castString(top['comment.utf-8']) ?? _castString(top['comment']),
      ctime: _castDate(top['creation date']),
      announces: announce,
      webseeds: webseeds.where((e) => e.isNotEmpty).toList(),
      storage: storage,
    );
  }
}
