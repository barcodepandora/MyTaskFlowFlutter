import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityX on TaskPriority {
  String get label => switch (this) {
        TaskPriority.low => 'Baja',
        TaskPriority.medium => 'Media',
        TaskPriority.high => 'Alta',
        TaskPriority.urgent => 'Urgente',
      };

  Color get color => switch (this) {
        TaskPriority.low => Colors.green,
        TaskPriority.medium => Colors.orange,
        TaskPriority.high => Colors.red,
        TaskPriority.urgent => Colors.purple,
      };

  int get colorValue => color.toARGB32();
}
