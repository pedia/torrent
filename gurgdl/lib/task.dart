import 'base/enum_utils.dart';

enum TaskType {
  torrent,
  magnet,
  ed2k,
}

class Task {
  Task({
    required this.source,
    required this.type,
    this.name,
  });

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        source: map['source'] as String,
        type: EnumUtils<TaskType>(TaskType.values)
            .enumEntry(map['type'] as String)!,
        name: map['name'] as String?,
      );

  final String source;
  final TaskType type;
  String? name;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'source': source,
        'name': name,
      };
}
