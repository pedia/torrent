import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'stats.dart';
import 'view/flipnum.dart';

class SessionPanel extends StatelessWidget {
  const SessionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<Stats>();
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Container(
          margin: const EdgeInsets.all(18),
          child: Column(
            children: [
              // FlipNumber(
              //   value: model.currentD,
              //   duration: const Duration(seconds: 1),
              //   textStyle: textTheme.headlineLarge,
              // ),
              // TestFlip(
              //   model.currentD,
              //   textStyle: textTheme.headlineLarge,
              // ),
              TestFlip(
                state.d1,
                textStyle: textTheme.headlineLarge,
              ),
              // TestFlip(
              //   model.d2,
              //   textStyle: textTheme.headlineLarge,
              // ),
              // Text('${model.currentD}',
              //     style: textTheme.headlineLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Icon(Icons.arrow_downward),
                  const SizedBox(width: 8),
                  Text(state.rateOfD.readable, style: textTheme.headlineLarge),
                  Text(state.rateOfD.unit, style: textTheme.bodySmall),
                  const SizedBox(width: 40),
                  const Icon(Icons.arrow_upward),
                  const SizedBox(width: 8),
                  Text(state.rateOfU.readable, style: textTheme.headlineLarge),
                  Text(state.rateOfU.unit, style: textTheme.bodySmall),
                ],
              ),
            ],
          )),
    );
  }
}
