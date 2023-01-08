import 'package:libtorrent/libtorrent.dart';

export 'package:libtorrent/libtorrent.dart';

class Torrent {
  final Handle handle;
  final List<int> sizes;
  bool metadata = false;
  Torrent(this.handle, {this.sizes = const <int>[]});
}
