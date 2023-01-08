import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'stats.dart';

class SessionPanel extends StatelessWidget {
  const SessionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<Stats>(
      builder: (context, _, model) => Card(
        child: Container(
            margin: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text('${model.currentD}',
                    style: Theme.of(context).textTheme.headlineLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Icon(Icons.arrow_downward),
                    const SizedBox(width: 8),
                    Text(model.rateOfD.readable,
                        style: Theme.of(context).textTheme.headlineLarge),
                    Text(model.rateOfD.unit,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 40),
                    const Icon(Icons.arrow_upward),
                    const SizedBox(width: 8),
                    Text(model.rateOfU.readable,
                        style: Theme.of(context).textTheme.headlineLarge),
                    Text(model.rateOfU.unit,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            )),
      ),
    );
  }
}
