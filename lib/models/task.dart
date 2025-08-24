import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high }
enum TaskStatus { todo, inProgress, done }

class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final String? assignee;
  final List<String> assignees;
  final DateTime? dueDate;
  final TaskStatus status;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final Timestamp? deadline;
  final String? boardId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.assignee,
    this.assignees = const [],
    this.dueDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.deadline,
    this.boardId,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    String? assignee,
    List<String>? assignees,
    DateTime? dueDate,
    TaskStatus? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? deadline,
    String? boardId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      assignee: assignee ?? this.assignee,
      assignees: assignees ?? this.assignees,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deadline: deadline ?? this.deadline,
      boardId: boardId ?? this.boardId,
    );
  }

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == 'TaskPriority.' + (data['priority'] ?? 'low'),
        orElse: () => TaskPriority.low,
      ),
      assignee: data['assignee'],
      assignees: List<String>.from(data['assignees'] ?? []),
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == 'TaskStatus.' + (data['status'] ?? 'todo'),
        orElse: () => TaskStatus.todo,
      ),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      deadline: data['deadline'],
      dueDate: data['deadline'] != null ? (data['deadline'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = {
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'assignees': assignees,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };

    if (assignee != null) {
      map['assignee'] = assignee!;
    }

    if (deadline != null) {
      map['deadline'] = deadline!;
    }

    return map;
  }
}