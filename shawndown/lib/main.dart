import 'dart:io';

import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_size/window_size.dart';

import 'homepage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tray = SystemTray();
  tray
      .initSystemTray(
    iconPath: Platform.isWindows ? 'assets/app.ico' : 'assets/app_icon_32.png',
    toolTip: 'GurgleDL',
  )
      .then((b) {
    tray.registerSystemTrayEventHandler((eventName) {
      debugPrint('tray $eventName');
      if (eventName == kSystemTrayEventClick) {
        setWindowVisibility(visible: true);
      } else if (eventName == kSystemTrayEventRightClick) {
        setWindowVisibility(visible: true);
      }
    });
  });

  runApp(const MyApp());

  tray.destroy().then((value) => null);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gurgle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Material(child: HomePage()),
    );
  }
}
