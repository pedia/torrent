import 'dart:io';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:torrent/torrent.dart';
import 'package:torrent/error.dart';

final folder = '../libtorrent/test/test_torrents';

Torrent? doParse(String filename) {
  final file = File('$folder/$filename');
  final bytes = file.readAsBytesSync();

  return Torrent.parse(bytes);
}

class CodeMatch extends Matcher {
  final ErrorCode code;
  const CodeMatch(this.code);
  @override
  bool matches(Object? item, Map matchState) {
    if (item is TorrentError) {
      return item.code == code;
    }
    addStateInfo(matchState, {'type': item});
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('code not match, desire $code');
}

main() {
  test('ParseTest', () {
    // final fn = '../torrent_tracker/example/test.torrent';
    final fn = '../torrent_model/test/sample.torrent';
    // final fn = '../libtorrent/test/test_torrents/zero2.torrent';
    // final fn = '../libtorrent/test/test_torrents/v2_multiple_files.torrent';
    final bytes = File(fn).readAsBytesSync();

    final t = Torrent.parse(bytes);
  }, skip: !File('../libtorrent').existsSync());

  test('TorrentInfoTest', () {
    final tests = {
      'base.torrent': (Torrent t) {
        expect(t, isNotNull);
        expect(t.files?.length, 1);
        expect(t.files?[0].path, 'temp');
      },
      'empty_path.torrent': (Torrent t) {
        expect(t, isNotNull);
        expect(t.files?.length, 1);
        expect(t.files?[0].path, 'temp');
      },
      'parent_path.torrent': (Torrent t) {
        expect(t, isNotNull);
        expect(t.files?.length, 1);
        expect(t.files?[0].path, 'temp/bar');
      },
      'hidden_parent_path.torrent': (Torrent t) {
        expect(t, isNotNull);
        expect(t.files?.length, 1);
        expect(t.files?[0].path, 'temp/foo/bar/bar');
      },
      'single_multi_file.torrent': (Torrent t) {
        expect(t, isNotNull);
        expect(t.files?.length, 1);
        expect(t.files?[0].path, 'temp/foo/bar');
      },
      'slash_path.torrent': (Torrent t) {
        expect(t.files?.length, 1);
        expect(t.files?[0].path, 'temp/bar');
      },
      'slash_path2.torrent': (Torrent t) {
        expect(t.files?.length, 1);
        expect(t.files?[0].path, 'temp/abc/def/bar');
      },
      'slash_path3.torrent': (Torrent t) {
        expect(t.files?.length, 1);
        expect(t.files?[0].path, 'temp/abc');
      },
      'backslash_path.torrent': (Torrent t) {
        expect(t.files?.length, 1);
        expect(t.files?[0].path, 'temp/bar');
      },
      'url_list.torrent': (Torrent t) {
        expect(t.webseeds.isEmpty, isTrue);
      },
      'url_list2.torrent': (Torrent t) {
        expect(t.webseeds.isEmpty, isTrue);
      },
      'url_list3.torrent': (Torrent t) {
        expect(t.webseeds.isEmpty, isTrue);
      },
      'httpseed.torrent': (Torrent t) {
        expect(t.webseeds.isNotEmpty, isTrue);
      },
      'empty_httpseed.torrent': (Torrent t) {
        expect(t.webseeds.isEmpty, isTrue);
      },
      'long_name.torrent': (Torrent t) {
        expect(t.files?.length, 1);
        expect(t.files?[0].path.length, 300);
      },
      'whitespace_url.torrent': (Torrent t) {
        expect(t.announces[0], 'udp://test.com/announce');
      },
      'duplicate_files.torrent': (Torrent t) {
        expect(t.files?.length, 2);
        expect(t.files?[0].path, 'temp/foo/bar.txt');
        // TODO: expect(t.files?[1].path, 'temp/foo/bar.1.txt');
      },
      'pad_file.torrent': (t) {
        expect(t.files?.length, 2);
      }

      //
      // 'v2.torrent': (t) {},
    };

    for (var e in tests.entries) {
      final t = doParse(e.key);
      e.value(t!);
    }
  });

  final failedFiles = {
    "missing_piece_len.torrent": ErrorCode.torrentMissingPieceLength,
    "invalid_piece_len.torrent": ErrorCode.torrentMissingPieceLength,
    "negative_piece_len.torrent": ErrorCode.torrentMissingPieceLength,
    "no_name.torrent": ErrorCode.torrentMissingName,
    "bad_name.torrent": ErrorCode.torrentMissingName,
    "invalid_name.torrent": ErrorCode.torrentMissingName,
    "invalid_info.torrent": ErrorCode.torrentMissingInfo,
    "string.torrent": ErrorCode.torrentIsNoDict,
    "negative_size.torrent": ErrorCode.torrentInvalidLength,
    "negative_file_size.torrent": ErrorCode.torrentInvalidLength,
    "invalid_path_list.torrent": ErrorCode.torrentInvalidName,
    "missing_path_list.torrent": ErrorCode.torrentMissingName,
    "invalid_pieces.torrent": ErrorCode.torrentMissingPieces,
    "unaligned_pieces.torrent": ErrorCode.torrentInvalidHashes,
    "invalid_file_size.torrent": ErrorCode.torrentInvalidLength,
    "invalid_symlink.torrent": ErrorCode.torrentInvalidName,
    "many_pieces.torrent": ErrorCode.tooManyPiecesInTorrent,
    "no_files.torrent": ErrorCode.noFilesInTorrent,
    "zero.torrent": ErrorCode.torrentInvalidLength,
    "zero2.torrent": ErrorCode.torrentInvalidLength,
    "v2_mismatching_metadata.torrent": ErrorCode.torrentInconsistentFiles,
    "v2_no_power2_piece.torrent": ErrorCode.torrentMissingPieceLength,
    "v2_invalid_file.torrent": ErrorCode.torrentFileParseFailed,
    "v2_deep_recursion.torrent": ErrorCode.torrentFileParseFailed,
    "v2_non_multiple_piece_layer.torrent": ErrorCode.torrentInvalidPieceLayer,
    "v2_piece_layer_invalid_file_hash.torrent":
        ErrorCode.torrentInvalidPieceLayer,
    "v2_invalid_piece_layer.torrent": ErrorCode.torrentInvalidPieceLayer,
    "v2_invalid_piece_layer_size.torrent": ErrorCode.torrentInvalidPieceLayer,
    "v2_bad_file_alignment.torrent": ErrorCode.torrentInconsistentFiles,
    "v2_unordered_files.torrent": ErrorCode.invalidBencoding,
    "v2_overlong_integer.torrent": ErrorCode.invalidBencoding,
    "v2_missing_file_root_invalid_symlink.torrent":
        ErrorCode.torrentMissingPiecesRoot,
    "v2_large_file.torrent": ErrorCode.torrentInvalidLength,
    "v2_large_offset.torrent": ErrorCode.tooManyPiecesInTorrent,
    "v2_piece_size.torrent": ErrorCode.torrentMissingPieceLength,
    "v2_invalid_pad_file.torrent": ErrorCode.torrentInvalidPadFile,
    "v2_zero_root.torrent": ErrorCode.torrentMissingPiecesRoot,
    "v2_zero_root_small.torrent": ErrorCode.torrentMissingPiecesRoot,
  };

  test('FailedTest', () async {
    for (var e in failedFiles.entries) {
      expect(() => doParse(e.key), throwsA(CodeMatch(e.value)));
    }
  }, skip: !File(folder).existsSync());
}
