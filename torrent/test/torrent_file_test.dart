import 'dart:io';
import 'package:test/scaffolding.dart';
import 'package:torrent/src/torrent_file.dart';
import 'package:torrent/torrent.dart';

main() {
  test('description', () async {
    // final fn = '../torrent_tracker/example/test.torrent';
    final fn = '../torrent_model/test/sample.torrent';
    // final fn = '../libtorrent/test/test_torrents/zero2.torrent';
    // final fn = '../libtorrent/test/test_torrents/v2_multiple_files.torrent';
    final content = File(fn).readAsBytesSync();

    final t = await Torrent.parse(content);
    return;

    final dir = Directory('../libtorrent/test/test_torrents');
    if (!dir.existsSync()) return;

    dir.list().listen((e) {
      if (e is File && e.path.endsWith('.torrent')) {
        // print(e.path);
        parse(e)
            .then((torrent) => print('${e.path}, $torrent'))
            .catchError((error, stackTrace) => print('$error ${e.path}'));
      }
    });
  });
}
