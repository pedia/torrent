import 'dart:io';
import 'dart:async';

import 'package:torrent/torrent.dart';

Future<Torrent> parse(File file) {
  final completer = Completer<Torrent>();

  file.readAsBytes().then((content) {
    completer.complete(Torrent.parse(content));
  })
      // .catchError((err) {
      //   completer.completeError(err);
      // })
      ;

  return completer.future;
}
