import 'dart:async';
import 'package:flutter/material.dart';
import 'tile.dart';
import 'session_panel.dart';
import 'stats.dart';
import 'torrent.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {
  int _counter = 0;
  late Session sess;
  final torrents = <int, Torrent>{};
  late Timer timer;
  final stats = Stats();
  int _tick = 0;

  void tick(_) {
    setState(() => _counter++);

    final as = sess.alerts;
    print('alerts ${as.length}');

    for (int i = 0; i < as.length; i++) {
      final a = as.itemOf(i);

      if (!a.what.endsWith('log') &&
          a.what != 'stats' &&
          a.what != 'session_stats' &&
          !a.what.endsWith('ing')) print('$a ${a.cast()}');

      if (a.type == 57) {
        final sa = a.toStats();
        if (sa != null) {
          stats.apply(StatsItem.from(sa));
        }
        continue;
      } else if (a.type == 70) {
        final ssa = a.toSessionStats();
        if (ssa != null) {
          stats.tick(ssa);
        }
        continue;
      }

      final h = a.torrentHandle;
      if (h != null) {
        setState(() => torrents[h.id] = Torrent(h));
      }
    }
    if (_tick++ % 2 == 0) {
      sess.postStats();
    }
  }

  @override
  void initState() {
    final p = SessionParams.readFrom('.sess');
    sess = Session.create(p);

    applySetting();

    timer = Timer.periodic(const Duration(seconds: 1), tick);

    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();

    quit();
    super.dispose();
  }

  void applySetting() {
    final p = sess.settingsPack;
    final o = p.getInt(SetName.alertMask);
    p.setInt(
      SetName.alertMask,
      o |
          AlertCategory.connect |
          AlertCategory.blockProgress |
          AlertCategory.tracker |
          AlertCategory.performanceWarning |
          // AlertCategory.dht |
          AlertCategory.stats |
          // AlertCategory.sessionLog |
          // AlertCategory.torrentLog |
          // too much: AlertCategory.dhtLog |
          AlertCategory.portMappingLog |
          AlertCategory.status,
    );
    sess.apply(p);
  }

  void quit() {
    print('quit');
    sess.state.write('.sess');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_counter'),
        actions: [
          IconButton(
            icon: Icon(sess.isPaused() ? Icons.start : Icons.pause),
            onPressed: () => sess.isPaused() ? sess.resume() : sess.pause(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              sess.add(AddTorrentParams.parseMagnet(
                'magnet:?xt=urn:btih:3c80d623bf867337d843d3727cae7053b23e9b4e',
                '.',
              ));
              sess.add(AddTorrentParams.parseMagnet(
                'magnet:?xt=urn:btih:0497dca6eaf2340ce4f1a982047dcafa738a6170',
                '.',
              ));
            },
          )
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              SessionPanel(stats: stats),
              Expanded(
                child: ListView.builder(
                  itemCount: torrents.length,
                  itemBuilder: (context, index) => Tile(
                    handle: torrents.entries.toList()[index].value.handle,
                  ),
                ),
              ),
            ],
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => tick(1),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
