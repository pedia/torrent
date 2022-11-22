import 'dart:typed_data';
import 'package:crypto/crypto.dart' show Digest;

import 'package:torrent/bencode.dart';
import 'package:torrent/src/file_storage.dart';
import 'package:torrent/src/url_utils.dart';

import 'error.dart';
import 'magnet_uri.dart';

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

class Torrent {
  final String? name;
  final String? comment;
  final String? createdBy;
  final DateTime? ctime;
  final Set<Uri> announces;
  final Set<Uri> webseeds;

  final int version;

  final FileStorage? storage;

  Torrent({
    this.version = 0,
    this.name,
    this.comment,
    this.createdBy,
    this.ctime,
    Set<Uri>? announces,
    Set<Uri>? webseeds,
    this.storage,
  })  : announces = announces ?? <Uri>{},
        webseeds = webseeds ?? <Uri>{};

  List<File>? get files => storage?.files;

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

  @override
  String toString() => 'Torrent($name)';

  static buildV2(FileStorage storage, Object fileTree, Map info) {
    if (fileTree is! Map) {
      throw TorrentError(ErrorCode.torrentFileParseFailed);
    }
  }

  static buildV1(FileStorage storage, Object files, Map info, String root,
      Uint8List pieces) {
    if (files is List) {
      for (var file in files) {
        if (file is Map) {
          buildSingleFile(storage, file, root, pieces);
        }
      }
    }
  }

  static buildSingleFile(
      FileStorage storage, Map info, String root, Uint8List pieces) {
    String? pathKey;

    if (info.containsKey('path.utf-8')) {
      pathKey = 'path.utf-8';
    } else if (info.containsKey('path')) {
      pathKey = 'path';
    }

    String? path;

    if (pathKey != null && info[pathKey] is List) {
      path =
          (info[pathKey] as List).map((x) => String.fromCharCodes(x)).join('/');

      path = '$root/$path';
    } else {
      path ??= root;
    }

    path = sanitizePath(path);

    final mtime = _castInt(info['mtime']);

    storage.add(
      File(
        path: path,
        size: _castInt(info['length']) ?? 0,
        filehash: Digest(pieces),
        mtime: mtime,
      ),
    );
  }

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
        final p = AddParam.parse(uri);
        // infoHashs
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
      name: name,
    );

    final pieces = info['pieces'];
    if (pieces == null) {
      throw TorrentError(ErrorCode.torrentMissingPieces);
    }

    final fileTree = info['file tree'];
    final files = info['files'];

    if (version >= 2 && fileTree != null) {
      buildV2(storage, fileTree, info);
    } else if (files != null) {
      buildV1(storage, files, info, name, pieces);
    } else {
      buildSingleFile(storage, info, name, pieces);
    }

    // throw TorrentError(ErrorCode.torrentMissingFileTree);

    // http seeds
    final webseeds = _castByteStringList(top['url-list'])
        .map((e) => sanitizeUrl(e))
        .takeWhile((e) => e != null)
        .toSet()
        .cast<Uri>();

    final seeds = _castStringList(top['httpseeds'])
        ?.map((e) => sanitizeUrl(e))
        .takeWhile((e) => e != null)
        .toSet()
        .cast<Uri>();
    if (seeds != null) webseeds.addAll(seeds);

    //
    final announces = _castByteStringList(top['announce-list'])
        .map((e) => sanitizeUrl(e))
        .takeWhile((e) => e != null)
        .toSet()
        .cast<Uri>();
    final announce = sanitizeUrl(_castString(top['announce']));
    if (announce != null) announces.add(announce);

    return Torrent(
      name: name,
      createdBy: _castString(top['createdBy']),
      comment: _castString(top['comment']),
      ctime: _castDate(top['creation date']),
      announces: announces,
      webseeds: webseeds,
      storage: storage,
    );
  }
}
