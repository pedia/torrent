import 'package:flutter/material.dart';
import 'package:libtorrent/libtorrent.dart';
import 'stats.dart';

class SessionPanel extends StatefulWidget {
  final Stats stats;
  const SessionPanel({super.key, required this.stats});

  @override
  State<SessionPanel> createState() => _SessionPanelState();
}

class _SessionPanelState extends State<SessionPanel> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
          margin: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Icon(Icons.arrow_upward),
                  const SizedBox(width: 8),
                  Text(widget.stats.speedOfUpload.readable,
                      style: Theme.of(context).textTheme.headlineLarge),
                  Text(widget.stats.speedOfUpload.unit,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 40),
                  const Icon(Icons.arrow_downward),
                  const SizedBox(width: 8),
                  Text(widget.stats.speedOfDownload.readable,
                      style: Theme.of(context).textTheme.headlineLarge),
                  Text(widget.stats.speedOfDownload.unit,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Icon(Icons.arrow_upward),
                  const SizedBox(width: 8),
                  Text(widget.stats.rateOfU.readable,
                      style: Theme.of(context).textTheme.headlineLarge),
                  Text(widget.stats.rateOfU.unit,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 40),
                  const Icon(Icons.arrow_downward),
                  const SizedBox(width: 8),
                  Text(widget.stats.rateOfD.readable,
                      style: Theme.of(context).textTheme.headlineLarge),
                  Text(widget.stats.rateOfD.unit,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          )),
    );
  }
}
