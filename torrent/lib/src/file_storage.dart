import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../error.dart';
import 'url_utils.dart';

class File {
  /// the full path of this file. The paths are unicode strings encoded in UTF-8.
  final String path;

  /// the path which this is a symlink to, or empty if this is
  /// not a symlink. This field is only used if the ``symlink_attribute`` is set.
  final String? symlink;

  // the offset of this file inside the torrent
  final int offset;

  /// the size of the file (in bytes) and ``offset`` is the byte offset
  /// of the file within the torrent. i.e. the sum of all the sizes of the files
  /// before it in the list.
  final int size;

  /// the modification time of this file specified in posix time.
  int? mtime;

  /// a SHA-1 hash of the content of the file, or zeros, if no
  /// file hash was present in the torrent file. It can be used to potentially
  /// find alternative sources for the file.
  final Digest hash;

  // set to true for files that are not part of the data of the torrent.
  // They are just there to make sure the next file is aligned to a particular byte offset
  // or piece boundary. These files should typically be hidden from an end user. They are
  // not written to disk.
  // bool pad_file:1;

  // true if the file was marked as hidden (on windows).
  // bool hidden_attribute:1;

  // true if the file was marked as executable (posix)
  // bool executable_attribute:1;

  // true if the file was a symlink. If this is the case
  // the ``symlink_index`` refers to a string which specifies the original location
  // where the data for this file was found.
  // bool symlink_attribute:1;

  File({
    required this.path,
    this.symlink,
    this.offset = 0,
    required this.size,
    required this.hash,
    this.mtime,
  });
}

/// The [FileStorage] class represents a file list and the piece
/// size. Everything necessary to interpret a regular bittorrent storage
/// file structure.
class FileStorage {
  /// the number of bytes in a regular piece
  /// (i.e. not the potentially truncated last piece)
  final int pieceLenth;

  // the number of pieces in the torrent
  // int m_num_pieces = 0;

  /// name of torrent. For multi-file torrents
  /// this is always the root directory
  final String name;

  /// the sum of all file sizes
  // final int totalSize;

  final files = <File>[];

  void add(File file) => files.add(file);

  FileStorage({
    required this.pieceLenth,
    required this.name,
    // required this.totalSize,
  });

  buildV2(Object fileTree, Map info) {
    if (fileTree is! Map) {
      throw TorrentError(ErrorCode.torrentFileParseFailed);
    }
  }

  buildV1(Object fileNames, Uint8List pieces) {
    if (fileNames is List) {
      for (var fn in fileNames) {
        buildSingleFile(fileName: fn, length: 0, pieces: pieces);
      }
    }
  }

  buildSingleFile({
    String? fileName,
    required int length,
    int? mtime,
    required Uint8List pieces,
  }) {
    var path = fileName != null ? '$name/$fileName' : name;

    add(File(
      path: path,
      size: length,
      hash: Digest(pieces),
      mtime: mtime,
    ));
  }
}
