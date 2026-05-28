import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'task_priority.dart';

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.category,
    required this.priority,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.create({
    required String title,
    required String description,
    required DateTime dueDate,
    required String category,
    required TaskPriority priority,
  }) {
    final now = DateTime.now();
    return Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      category: category,
      priority: priority,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String category;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOverdue =>
      !isCompleted && dueDate.isBefore(DateTime.now());

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? category,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id];
}
