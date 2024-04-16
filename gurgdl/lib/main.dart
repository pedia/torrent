// import 'dart:ffi';
// import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:libtorrent/libtorrent.dart';
import 'package:path/path.dart' as ph;
import 'package:provider/provider.dart';
// import 'package:system_tray/system_tray.dart';
// import 'package:window_size/window_size.dart';

import 'homepage.dart';
import 'session.dart';
import 'stats.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  print(ph.current);

  Libtc.bind();

  // final tray = SystemTray();
  // tray
  //     .initSystemTray(
  //   iconPath: Platform.isWindows ? 'assets/app.ico' : 'assets/app_icon_32.png',
  //   toolTip: 'GurgleDL',
  // )
  //     .then((b) {
  //   tray.registerSystemTrayEventHandler((eventName) {
  //     debugPrint('tray $eventName');
  //     if (eventName == kSystemTrayEventClick) {
  //       setWindowVisibility(visible: true);
  //     } else if (eventName == kSystemTrayEventRightClick) {
  //       setWindowVisibility(visible: true);
  //     }
  //   });
  // });

  runApp(const MyApp());

  // tray.destroy().then((value) => null);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SessionController? sc;

  @override
  void initState() {
    // FlutterWindowClose.setWindowShouldCloseHandler(() async {
    //   sc?.dispose();
    //   return true;
    // });

    sc = SessionController.createSession('.');
    super.initState();
  }

  @override
  void dispose() {
    sc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gurgle',
      theme: ThemeData(useMaterial3: true, primaryColor: Colors.green),
      home: sc == null
          ? const Material(child: Center(child: Text('loading')))
          : MultiProvider(
              providers: [
                ChangeNotifierProvider<SessionController>.value(value: sc!),
                ChangeNotifierProvider<Stats>.value(value: sc!.stats),
              ],
              child: const HomePage(),
            ),
    );
  }
}
