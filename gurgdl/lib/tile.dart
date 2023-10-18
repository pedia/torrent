import 'package:flutter/material.dart';

import 'package:libtorrent/libtorrent.dart';
import 'status_panel.dart';
import 'task.dart';
import 'task_detail.dart';

// name               多行, selectable
// --->------------   progress
// 2/3  9 KB          finished file count / file count, speed
//
class TaskTile extends StatefulWidget {
  const TaskTile(this.t, {super.key});

  final Task t;

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  bool action = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.t.handle?.status;
    final info = widget.t.handle?.info;
    return Column(
      children: [
        ListTile(
          // titlecolor: colorForState(status.state),
          title: SelectableText(widget.t.name ?? widget.t.infoHash),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => TaskDetail(widget.t),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          subtitle: action
              ? null
              : LinearProgressIndicator(
                  value: status?.progress,
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
            child: status == null ? Container() : StatusPanel(status.inner),
          ),
        if (action)
          Row(
            children: [
              OutlinedButton(
                onPressed: widget.t.handle?.saveResumeData,
                child: const Text('save resume'),
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

///
class TaskSummary extends StatelessWidget {
  const TaskSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Flexible(flex: 5, child: Text('2/3')),
        Flexible(flex: 5, child: Container()),
        const Flexible(flex: 5, child: Text('9 KB/s')),
      ],
    );
  }
}

/// List all files in this task.
class FilesView extends StatelessWidget {
  const FilesView(this.t, {super.key});
  final Task t;

  @override
  Widget build(BuildContext context) {
    final files = t.handle!.info!.files;
    return SizedBox(
      height: 200,
      child: ListView(
        children: List.generate(
          files.numFiles,
          (i) => ListTile(
            // title: Text(files.fileName(i)),
            // subtitle: Text(Dimension.size(files.fileSize(i)).toString()),
            onTap: () {
              // t.queryFileSize();

              // TODO: order wrong?
              // debugPrint('sizes: ${t.sizes} ${t.handle.fileProgress}');
            },
          ),
        ),
      ),
    );
  }
}
