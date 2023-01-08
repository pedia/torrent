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
  final Torrent t;
  const Tile(this.t, {super.key});

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> {
  String pretty(Handle h) {
    final n1 = fromFixedArray(h.status.name);
    if (n1.isNotEmpty) {
      return n1;
    }
    return h.id.toString();
  }

  bool action = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.t.handle.status;
    final info = widget.t.handle.info;
    return Column(
      children: [
        ListTile(
          tileColor: colorForState(status.state),
          title: SelectableText(pretty(widget.t.handle)),
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
        if (action) FilesView(widget.t),
        if (action)
          SizedBox(
            // preferredSize: const Size.fromHeight(200),
            height: 200,
            child: StatusPanel(status),
          ),
        if (action)
          Row(
            children: [
              OutlinedButton(
                child: const Text('save resume'),
                onPressed: () => widget.t.handle.saveResumeData(),
              ),
            ],
          ),
      ],
    );
  }

  Color? colorForState(int state) => {
        TorrentState.queuedForChecking: Colors.pinkAccent,
        TorrentState.checkingFiles: Colors.red,
        TorrentState.downloadingMetadata: Colors.black12,
        TorrentState.downloading: Colors.transparent,
        TorrentState.finished: Colors.green,
        TorrentState.seeding: Colors.blue,
        TorrentState.allocating: Colors.pink,
        TorrentState.checkingResumeData: Colors.amber,
      }[state];
}

class FilesView extends StatelessWidget {
  final Torrent t;
  FilesView(this.t, {super.key});

  @override
  Widget build(BuildContext context) {
    final files = t.handle.info.files;
    return SizedBox(
      height: 200,
      child: ListView(
        children: List.generate(
          files.numFiles,
          (i) => ListTile(
            title: Text(files.fileName(i)),
            subtitle: Text(Dimension.size(files.fileSize(i)).toString()),
            onTap: () {
              t.queryFileSize();

              // TODO: order wrong?
              debugPrint('sizes: ${t.sizes}');
            },
          ),
        ),
      ),
    );
  }
}
