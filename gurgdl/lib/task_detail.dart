import 'package:flutter/material.dart';

import 'task.dart';

class TaskDetail extends StatefulWidget {
  const TaskDetail(this.task, {super.key});

  final Task task;

  @override
  State<TaskDetail> createState() => _TaskDetailState();
}

class _TaskDetailState extends State<TaskDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.toString()),
      ),
      body: Container(),
    );
  }
}
