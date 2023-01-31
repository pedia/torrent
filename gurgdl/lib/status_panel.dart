import 'package:flutter/material.dart';
import 'package:libtorrent/gen/libtorrent.g.dart' show Status;

import 'base/dimension.dart';

class Item {
  Item(this.name, this.fetch, [this.comment]);

  final String name;
  final Object Function() fetch;
  final String? comment;
}

class StatusPanel extends StatelessWidget {
  const StatusPanel(this.status, {super.key});
  final Status status;

  List<Item> items() => [
        Item('state', () => status.state),
        Item('next announce', () => status.nextAnnounce,
            '''the time until the torrent will announce itself to the tracker.'''),
        Item(
            'total_download',
            () => status.total_download,
            'the number of bytes downloaded and uploaded to all peers, accumulated, '
                '*this session* only. The session is considered to restart when a '
                'torrent is paused and restarted again. When a torrent is paused, these '
                'counters are reset to 0. If you want complete, persistent, stats, see '
                '``all_time_upload`` and ``all_time_download``.'),
        Item(
            'total_upload',
            () => status.total_upload,
            'the number of bytes downloaded and uploaded to all peers, accumulated, '
                '*this session* only. The session is considered to restart when a '
                'torrent is paused and restarted again. When a torrent is paused, these '
                'counters are reset to 0. If you want complete, persistent, stats, see '
                '``all_time_upload`` and ``all_time_download``.'),
        Item('total_payload_download',
            () => Dimension.size(status.total_payload_download)),
        Item('total_payload_upload',
            () => Dimension.size(status.total_payload_upload)),
        Item('total_failed_bytes', () => status.total_failed_bytes),
        Item('total_redundant_bytes', () => status.total_redundant_bytes),
        Item('download_rate',
            () => Dimension.speed(status.download_rate.toInt())),
        Item('upload_rate', () => Dimension.speed(status.upload_rate.toInt())),
        Item('download_payload_rate',
            () => Dimension.speed(status.download_payload_rate.toInt())),
        Item('upload_payload_rate',
            () => Dimension.speed(status.upload_payload_rate.toInt())),
        Item('num_seeds', () => status.num_seeds),
        Item('num_peers', () => status.num_peers),
        Item('num_complete', () => status.num_complete),
        Item('num_incomplete', () => status.num_incomplete),
        Item('list_seeds', () => status.list_seeds),
        Item('list_peers', () => status.list_peers),
        Item('connect_candidates', () => status.connect_candidates),
        Item('num_pieces', () => status.num_pieces),
        Item('total_done', () => Dimension.size(status.total_done)),
        Item('total_wanted_done',
            () => Dimension.size(status.total_wanted_done)),
        Item('total_wanted', () => status.total_wanted),
        Item('distributed_copies', () => status.distributed_copies),
        Item('block_size', () => status.block_size),
        Item('num_uploads', () => status.num_uploads),
        Item('num_connections', () => status.num_connections),
        Item('uploads_limit', () => status.uploads_limit),
        Item('connections_limit', () => status.connections_limit),
        Item('up_bandwidth_queue', () => status.up_bandwidth_queue),
        Item('down_bandwidth_queue', () => status.down_bandwidth_queue),
        Item('all_time_upload',
            () => Dimension.duration(status.all_time_upload)),
        Item('all_time_download',
            () => Dimension.duration(status.all_time_download)),
        Item('seed_rank', () => status.seed_rank),
        Item('has_incoming', () => status.has_incoming),
      ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: items()
          .map((i) => Row(
                children: [
                  // name ? value
                  // 8    1 8
                  Expanded(
                    flex: 8,
                    child: Text(i.name, textAlign: TextAlign.right),
                  ),
                  Expanded(
                    child: i.comment != null
                        ? Tooltip(
                            message: i.comment,
                            child: const Icon(Icons.info, size: 16),
                          )
                        : Container(),
                  ),
                  Expanded(
                    flex: 8,
                    child:
                        Text(i.fetch().toString(), textAlign: TextAlign.left),
                  ),
                ],
              ))
          .toList(),
    );
  }
}
