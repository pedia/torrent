import 'package:crypto/crypto.dart';

class File {
  final String path;
  final int size;
  final Digest filehash;
  final String? symlink;
  int offset;
  int? mtime;

  File({
    required this.path,
    required this.size,
    required this.filehash,
    this.symlink,
    this.offset = 0,
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
}
