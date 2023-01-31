import 'package:flutter/material.dart';
import 'package:gurgdl/view/flipnum.dart';
import 'package:provider/provider.dart';

void main() {
  final v = ValueNotifier<num>(103669);
  final v2 = ValueNotifier<int>(3);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: v),
        ChangeNotifierProvider.value(value: v2),
      ],
      builder: (context, child) => MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Material(
          child: Scaffold(
            body: Column(
              // color: Colors.white,
              children: [
                const SizedBox(height: 100),
                FlipNumber(
                  number: Provider.of<ValueNotifier<num>>(context).value,
                  duration: const Duration(seconds: 3),
                  textStyle: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.apply(color: Colors.red),
                  curve: Curves.easeOutCirc,
                ),
                const SizedBox(height: 100),
                FlipNumber(
                  number: -Provider.of<ValueNotifier<num>>(context).value,
                  duration: const Duration(seconds: 3),
                  textStyle: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.apply(color: Colors.red),
                  curve: Curves.easeInOutExpo,
                ),
                const SizedBox(height: 100),
                SingleDigitFlipCounter(
                  value:
                      Provider.of<ValueNotifier<int>>(context).value.toDouble(),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOutBack,
                  size: const Size(60, 90),
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                ),
                SingleDigitFlipCounter(
                  value:
                      Provider.of<ValueNotifier<int>>(context).value.toDouble(),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOutExpo,
                  size: const Size(60, 90),
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                v.value += 1111;
                v2.value += 1;
              },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    ),
  );
}
