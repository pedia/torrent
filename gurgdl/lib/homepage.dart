import 'dart:io';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:libtorrent/libtorrent.dart';
import 'package:provider/provider.dart';

import 'session.dart';
import 'session_panel.dart';
import 'task.dart';
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
            onPressed: () async {
              final hc = HttpClient();
              final req = await hc.getUrl(Uri.parse('http://baidu.com'));
              final resp = await req.close();
              print(resp.headers);
              hc.close(force: true);

              sc.add(Task.fromUri(
                // 'magnet:?xt=urn:btih:89ed9ed8e1adedf731ad2396ff786924a047da59&dn=[www.mp4so.com]敢死队4：最终章.2023.HD1080p.中英双字.mp4&tr=https://tracker.iriseden.fr:443/announce&tr=https://tr.highstar.shop:443/announce&tr=https://tr.fuckbitcoin.xyz:443/announce&tr=https://tr.doogh.club:443/announce&tr=https://tr.burnabyhighstar.com:443/announce&tr=https://t.btcland.xyz:443/announce&tr=http://vps02.net.orel.ru:80/announce&tr=https://tracker.kuroy.me:443/announce&tr=http://tr.cili001.com:8070/announce&tr=http://t.overflow.biz:6969/announce&tr=http://t.nyaatracker.com:80/announce&tr=http://open.acgnxtracker.com:80/announce&tr=http://nyaa.tracker.wf:7777/announce&tr=http://home.yxgz.vip:6969/announce&tr=http://buny.uk:6969/announce&tr=https://tracker.tamersunion.org:443/announce&tr=https://tracker.nanoha.org:443/announce&tr=https://tracker.loligirl.cn:443/announce&tr=udp://bubu.mapfactor.com:6969/announce&tr=http://share.camoe.cn:8080/announce&tr=udp://movies.zsw.ca:6969/announce&tr=udp://ipv4.tracker.harry.lu:80/announce&tr=udp://tracker.sylphix.com:6969/announce&tr=http://95.216.22.207:9001/announce',
                // 'magnet:?xt=urn:btih:3194991c30c68eb8b98efe2a885b2e16fe737864&dn=[www.mp4so.com]%E5%A4%8F%E6%B4%9B%E5%85%8B%E7%9A%84%E5%AD%A9%E5%AD%90%E4%BB%AC.%E7%94%B5%E5%BD%B1%E7%89%88.2023.BD1080p.%E4%B8%AD%E6%96%87%E5%AD%97%E5%B9%95.mp4&tr=https://tracker.iriseden.fr:443/announce&tr=https://tr.highstar.shop:443/announce&tr=https://tr.fuckbitcoin.xyz:443/announce&tr=https://tr.doogh.club:443/announce&tr=https://tr.burnabyhighstar.com:443/announce&tr=https://t.btcland.xyz:443/announce&tr=http://vps02.net.orel.ru:80/announce&tr=https://tracker.kuroy.me:443/announce&tr=http://tr.cili001.com:8070/announce&tr=http://t.overflow.biz:6969/announce&tr=http://t.nyaatracker.com:80/announce&tr=http://open.acgnxtracker.com:80/announce&tr=http://nyaa.tracker.wf:7777/announce&tr=http://home.yxgz.vip:6969/announce&tr=http://buny.uk:6969/announce&tr=https://tracker.tamersunion.org:443/announce&tr=https://tracker.nanoha.org:443/announce&tr=https://tracker.loligirl.cn:443/announce&tr=udp://bubu.mapfactor.com:6969/announce&tr=http://share.camoe.cn:8080/announce&tr=udp://movies.zsw.ca:6969/announce&tr=udp://ipv4.tracker.harry.lu:80/announce&tr=udp://tracker.sylphix.com:6969/announce&tr=http://95.216.22.207:9001/announce',
                // 'magnet:?xt=urn:btih:1e39370e5982e4f2524f703f109a1dea87cbb5f8&dn=[www.mp4so.com]%E9%A3%93%E9%A3%8E%E8%90%A5%E6%95%913.2023.BD1080p.%E5%9B%BD%E8%8B%B1%E5%8F%8C%E8%AF%AD.%E4%B8%AD%E8%8B%B1%E5%8F%8C%E5%AD%97.mp4&tr=https://tracker.iriseden.fr:443/announce&tr=https://tr.highstar.shop:443/announce&tr=https://tr.fuckbitcoin.xyz:443/announce&tr=https://tr.doogh.club:443/announce&tr=https://tr.burnabyhighstar.com:443/announce&tr=https://t.btcland.xyz:443/announce&tr=http://vps02.net.orel.ru:80/announce&tr=https://tracker.kuroy.me:443/announce&tr=http://tr.cili001.com:8070/announce&tr=http://t.overflow.biz:6969/announce&tr=http://t.nyaatracker.com:80/announce&tr=http://open.acgnxtracker.com:80/announce&tr=http://nyaa.tracker.wf:7777/announce&tr=http://home.yxgz.vip:6969/announce&tr=http://buny.uk:6969/announce&tr=https://tracker.tamersunion.org:443/announce&tr=https://tracker.nanoha.org:443/announce&tr=https://tracker.loligirl.cn:443/announce&tr=udp://bubu.mapfactor.com:6969/announce&tr=http://share.camoe.cn:8080/announce&tr=udp://movies.zsw.ca:6969/announce&tr=udp://ipv4.tracker.harry.lu:80/announce&tr=udp://tracker.sylphix.com:6969/announce&tr=http://95.216.22.207:9001/announce',
                'magnet:?xt=urn:btih:ad3e319ee062a0f85ffeec57da82a938a477d8b2&dn=[www.mp4so.com]%E6%97%A0%E5%A4%84%E9%80%A2%E7%94%9F.2023.HD1080p.%E4%B8%AD%E6%96%87%E5%AD%97%E5%B9%95.mp4&tr=https://tracker.iriseden.fr:443/announce&tr=https://tr.highstar.shop:443/announce&tr=https://tr.fuckbitcoin.xyz:443/announce&tr=https://tr.doogh.club:443/announce&tr=https://tr.burnabyhighstar.com:443/announce&tr=https://t.btcland.xyz:443/announce&tr=http://vps02.net.orel.ru:80/announce&tr=https://tracker.kuroy.me:443/announce&tr=http://tr.cili001.com:8070/announce&tr=http://t.overflow.biz:6969/announce&tr=http://t.nyaatracker.com:80/announce&tr=http://open.acgnxtracker.com:80/announce&tr=http://nyaa.tracker.wf:7777/announce&tr=http://home.yxgz.vip:6969/announce&tr=http://buny.uk:6969/announce&tr=https://tracker.tamersunion.org:443/announce&tr=https://tracker.nanoha.org:443/announce&tr=https://tracker.loligirl.cn:443/announce&tr=udp://bubu.mapfactor.com:6969/announce&tr=http://share.camoe.cn:8080/announce&tr=udp://movies.zsw.ca:6969/announce&tr=udp://ipv4.tracker.harry.lu:80/announce&tr=udp://tracker.sylphix.com:6969/announce&tr=http://95.216.22.207:9001/announce',
              )!);
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
            final task = Task.fromUri(value);
            if (task != null) {
              sc.add(task);
            }
          });
        },
        tooltip: 'Paste magnet',
        child: const Icon(Icons.add),
      ),
    );
  }
}
