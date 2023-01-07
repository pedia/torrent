import 'package:flutter/material.dart';
import 'package:libtorrent/libtorrent.dart';

import 'package:libtorrent/native_array.dart';

// name
// --->------------   progress
// 2/3  9 KB          finished file count / file count, speed
//
class Tile extends StatefulWidget {
  final Handle handle;
  const Tile({super.key, required this.handle});

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> {
  String prettyNameOf(Handle h) {
    final n1 = fromFixedArray(h.status.name);
    if (n1.isNotEmpty) {
      return n1;
    }
    return h.id.toUnsigned(32).toRadixString(16);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(prettyNameOf(widget.handle)),
      subtitle: Text('''${widget.handle.status.progress}
           D: ${widget.handle.status.total_download}
           U: ${widget.handle.status.total_upload}'''),
    );
  }
}
