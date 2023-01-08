import 'package:flutter/material.dart';

import 'package:libtorrent/native_array.dart';
import 'stats.dart';
import 'status_panel.dart';
import 'torrent.dart';

// name               多行, selectable
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
  String pretty(Handle h) {
    final n1 = fromFixedArray(h.status.name);
    if (n1.isNotEmpty) {
      return n1;
    }
    return h.id.toUnsigned(32).toRadixString(16);
  }

  bool action = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.handle.status;
    final info = widget.handle.info;
    return Column(
      children: [
        ListTile(
          tileColor: colorForState(status.state),
          title: SelectableText(pretty(widget.handle)),
          onTap: () => setState(() => action = !action),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          subtitle: LinearProgressIndicator(
            value: status.progress,
            color: Colors.green,
            minHeight: 4,
          ),
        ),
        // Text(info.name),
        // Text(info.creator),
        // Text(info.creationDate.toIso8601String()),
        // Text(info.comment),
        // Text(
        //     '${Dimension.size(info.totalSize)} ${Dimension.size(info.sizeOnDisk)}'),
        if (action)
          ...List.generate(info.numFiles,
              (i) => ListTile(title: Text(info.files.fileName(i)))).toList(),
        if (action)
          SizedBox(
            height: 200,
            child: StatusPanel(status),
          ),
      ],
    );
  }

  Color? colorForState(int state) => {
        TorrentState.queuedForChecking: Colors.pinkAccent,
        TorrentState.checkingFiles: Colors.red,
        TorrentState.downloadingMetadata: Colors.black26,
        TorrentState.downloading: Colors.transparent,
        TorrentState.finished: Colors.green,
        TorrentState.seeding: Colors.blue,
        TorrentState.allocating: Colors.pink,
        TorrentState.checkingResumeData: Colors.amber,
      }[state];
}

class FileView extends StatelessWidget {
  final String fileName;
  final String filePath;
  const FileView(this.fileName, this.filePath, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(fileName),
      onTap: () {},
    );
  }
}
