import 'dart:typed_data';
import 'package:crypto/crypto.dart' show Digest;

import 'package:torrent/bencode.dart';
import 'package:torrent/src/file_storage.dart';
import 'package:torrent/src/url_utils.dart';

import 'error.dart';

/// Helper extension for get String/List from BytesMap.
extension _SafeValue on Map {
  int? intOf(String key) => containsKey(key) ? this[key] as int : null;

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

    if (containsKey(key) && this[key] is List) {
      (this[key] as List).cast<List>().forEach((sublist) {
        for (final Uint8List i in sublist) {
          res.add(String.fromCharCodes(i));
        }
      });
    }

    return res;
  }

  List<String> stringListOf(String key) {
    if (containsKey(key)) {
      return (this[key] as List).map((i) => String.fromCharCodes(i)).toList();
    }
    return <String>[];
  }
}

class Torrent {
  final String? name;
  final String? comment;
  final String? createdBy;
  final DateTime? creationDate;
  final List<String> announce;
  final List<String> webseed;

  final int version;

  final FileStorage storage;

  Torrent({
    this.version = 0,
    this.name,
    this.comment,
    this.createdBy,
    this.creationDate,
    this.announce = const [],
    this.webseed = const [],
    required this.storage,
  });

  List<File> get files => storage.files;

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

    int? mtime = info.intOf('mtime');

    storage.add(File(
      path: path,
      size: info.intOf('length')!,
      filehash: digestFrom(pieces),
      mtime: mtime,
    ));
  }

  static Digest digestFrom(Uint8List buf) {
    return Digest(buf);
    // ByteData.view(buf.buffer).getUint32(0);
  }

  static Torrent? parse(Uint8List content) {
    final map = decodeBytes(content);
    if (map is! Map || map.isEmpty) {
      throw TorrentError(ErrorCode.torrentIsNoDict);
    }

    final top = map.cast<Object, Object>();

    if (!top.containsKey('info')) {
      String? uri = top.stringOf('magnet-uri');
      if (uri != null) {
        // TODO: parse magnet uri
      }

      throw TorrentError(ErrorCode.torrentMissingInfo);
    }

    // parse info section
    Object? info = top['info'];
    if (info is! Map) {
      throw TorrentError(ErrorCode.torrentInfoNoDict);
    }

    // TODO: info-hash

    // version
    int? version = info.intOf('meta version');
    if (version != null && version > 2) {
      throw TorrentError(ErrorCode.torrentUnknownVersion);
    }

    version ??= 1;

    // piece length
    int? pieceLength = info.intOf('piece length');
    if (pieceLength != null) {
      if (pieceLength <= 0 || pieceLength > 0x7fffffff / 2) {
        throw TorrentError(ErrorCode.torrentMissingPieceLength);
      }

      // according to BEP 52: "It must be a power of two and at least 16KiB."
      if (version > 1 &&
          (pieceLength < 16 * 1024 || (pieceLength & (pieceLength - 1)) != 0)) {
        throw TorrentError(ErrorCode.torrentMissingPieceLength);
      }
    }
    assert(pieceLength != null);

    // name
    String? name = info.stringOf('name.utf-8');
    name ??= info.stringOf('name');
    if (name == null) {
      throw TorrentError(ErrorCode.torrentMissingName);
    }

    // storage
    final storage = FileStorage(
      pieceLenth: pieceLength!,
      name: name,
    );

    final fileTree = info['file tree'];
    final files = info['files'];
    final pieces = info['pieces'];
    if (pieces == null) {
      throw TorrentError(ErrorCode.torrentMissingPieces);
    }

    if (version >= 2 && fileTree != null) {
      buildV2(storage, fileTree, info);
    } else if (files != null) {
      buildV1(storage, files, info, name, pieces);
    } else {
      buildSingleFile(storage, info, name, pieces);
    }

    // throw TorrentError(ErrorCode.torrentMissingFileTree);

    // http seeds
    List<String>? webseed;
    try {
      webseed = top.stringListOf('url-list');
    } catch (_) {}

    if (webseed == null) {
      try {
        webseed = top.stringListOf('url-list');
      } catch (_) {}
    }

    webseed ??= [];
    webseed.addAll(top.stringListOf('httpseeds'));

    webseed =
        webseed.map((x) => sanitizeUrl(x)!).where((x) => x.isNotEmpty).toList();

    //
    List<String> announce = top.expandStringListOf('announce-list');

    String? url = sanitizeUrl(top.stringOf('announce'));
    if (url != null && url.isNotEmpty) {
      announce.insert(0, url);
    }

    return Torrent(
      name: name,
      createdBy: top.stringOf('createdBy'),
      comment: top.stringOf('comment'),
      creationDate: top.dateOf('creation date'),
      announce: announce,
      webseed: webseed,
      storage: storage,
    );
  }
}
