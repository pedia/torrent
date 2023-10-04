import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'session.dart';
import 'task.dart';
import 'session_panel.dart';
import 'tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final sc = context.read<SessionController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('GurgleDL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: sc.save,
          ),
          IconButton(
            icon: Icon(sc.sess.isPaused() ? Icons.start : Icons.pause),
            onPressed: sc.toggle,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              sc.add(Task.fromUri(
                  'magnet:?xt=urn:btih:3c80d623bf867337d843d3727cae7053b23e9b4e')!);
              // sc.sess.add(AddTorrentParams.parseMagnet(
              //   'magnet:?xt=urn:btih:0497dca6eaf2340ce4f1a982047dcafa738a6170',
              //   '.',
              // )!);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            const SessionPanel(),
            Expanded(
              child: ListView.builder(
                itemCount: sc.tasks.length,
                itemBuilder: (context, index) => TaskTile(
                  sc.tasks.entries.elementAt(index).value,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FlutterClipboard.paste().then((value) {
            debugPrint('pasted $value');
            final p = AddTorrentParams.parseMagnet(value, '.');
            if (p != null) {
              sc.sess.add(p);
            }
          });
        },
        tooltip: 'Paste magnet',
        child: const Icon(Icons.add),
      ),
    );
  }
}
