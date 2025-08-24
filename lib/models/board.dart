

import 'dart:ui';

import 'package:trello/models/task.dart';

class Board {
  final String id;
  String title;
  String description;
  final Color color;
  final List<Task> tasks;

  Board({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.tasks,
  });

  Board copyWith({
    String? id,
    String? title,
    String? description,
    Color? color,
    List<Task>? tasks,
  }) {
    return Board(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      tasks: tasks ?? this.tasks,
    );
  }
}
