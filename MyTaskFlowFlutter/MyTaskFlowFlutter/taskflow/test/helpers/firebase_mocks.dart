import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/network/network_info.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';

class MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}

class MockUserCredential extends Mock implements fb.UserCredential {}

class MockFirebaseUser extends Mock implements fb.User {}

class FakeNetworkInfo implements NetworkInfo {
  FakeNetworkInfo({bool connected = true}) : _connected = connected;
  final bool _connected;

  @override
  Future<bool> get isConnected async => _connected;
}

Task makeTask({
  String id = 'task-1',
  String title = 'Test Task',
  String description = 'desc',
  bool isCompleted = false,
  TaskPriority priority = TaskPriority.medium,
  String category = 'Personal',
  DateTime? dueDate,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 1, 1);
  return Task(
    id: id,
    title: title,
    description: description,
    dueDate: dueDate ?? now.add(const Duration(days: 1)),
    category: category,
    priority: priority,
    isCompleted: isCompleted,
    createdAt: now,
    updatedAt: now,
  );
}
