import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart' hide Task;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/tasks/data/datasources/firebase_task_datasource.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';

import '../../../../helpers/firebase_mocks.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseUser mockUser;
  late FirebaseTaskDatasource datasource;

  const testUserId = 'test-user-id';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockFirebaseUser();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn(testUserId);

    datasource = FirebaseTaskDatasource(
      firestore: fakeFirestore,
      auth: mockAuth,
      networkInfo: FakeNetworkInfo(connected: true),
    );
  });

  group('getAllTasks', () {
    test('returns empty list when no tasks exist', () async {
      final result = await datasource.getAllTasks();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (tasks) {
        expect(tasks, isEmpty);
      });
    });

    test('returns only tasks belonging to current user', () async {
      final task = makeTask();
      await datasource.createTask(task);

      await fakeFirestore.collection('tasks').doc('other-task').set({
        'userId': 'other-user',
        'title': 'Other task',
        'description': '',
        'dueDate': Timestamp.fromDate(DateTime(2026, 2, 1)),
        'category': 'Personal',
        'priority': 'medium',
        'isCompleted': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      final result = await datasource.getAllTasks();

      result.fold((_) => fail('Expected Right'), (tasks) {
        expect(tasks.length, 1);
        expect(tasks.first.id, task.id);
      });
    });

    test('returns list with all user tasks', () async {
      await datasource.createTask(makeTask(id: 'task-1', title: 'Task 1'));
      await datasource.createTask(makeTask(id: 'task-2', title: 'Task 2'));

      final result = await datasource.getAllTasks();

      result.fold((_) => fail('Expected Right'), (tasks) {
        expect(tasks.length, 2);
      });
    });
  });

  group('createTask', () {
    test('creates task in Firestore with correct userId', () async {
      final task = makeTask();
      final result = await datasource.createTask(task);

      expect(result.isRight(), isTrue);

      final snap = await fakeFirestore.collection('tasks').doc(task.id).get();
      expect(snap.exists, isTrue);
      expect(snap.data()!['userId'], testUserId);
      expect(snap.data()!['title'], task.title);
    });

    test('returns Right(task) on success', () async {
      final task = makeTask();
      final result = await datasource.createTask(task);

      result.fold((_) => fail('Expected Right'), (t) {
        expect(t.id, task.id);
        expect(t.title, task.title);
      });
    });
  });

  group('updateTask', () {
    test('updates existing task fields', () async {
      final task = makeTask();
      await datasource.createTask(task);

      final updated = task.copyWith(title: 'Updated', isCompleted: true);
      final result = await datasource.updateTask(updated);

      expect(result.isRight(), isTrue);

      final snap = await fakeFirestore.collection('tasks').doc(task.id).get();
      expect(snap.data()!['title'], 'Updated');
      expect(snap.data()!['isCompleted'], true);
    });

    test('returns TaskNotFoundFailure when task does not exist', () async {
      final task = makeTask(id: 'nonexistent');
      final result = await datasource.updateTask(task);

      expect(result, const Left(TaskNotFoundFailure()));
    });
  });

  group('deleteTask', () {
    test('removes task from Firestore', () async {
      final task = makeTask();
      await datasource.createTask(task);

      final result = await datasource.deleteTask(task.id);

      expect(result.isRight(), isTrue);

      final snap = await fakeFirestore.collection('tasks').doc(task.id).get();
      expect(snap.exists, isFalse);
    });

    test('returns TaskNotFoundFailure when task does not exist', () async {
      final result = await datasource.deleteTask('nonexistent');

      expect(result, const Left(TaskNotFoundFailure()));
    });
  });

  group('getTaskById', () {
    test('returns task when it exists', () async {
      final task = makeTask();
      await datasource.createTask(task);

      final result = await datasource.getTaskById(task.id);

      result.fold((_) => fail('Expected Right'), (t) {
        expect(t.id, task.id);
        expect(t.title, task.title);
      });
    });

    test('returns TaskNotFoundFailure when task does not exist', () async {
      final result = await datasource.getTaskById('nonexistent');

      expect(result, const Left(TaskNotFoundFailure()));
    });
  });

  group('searchTasks', () {
    setUp(() async {
      await datasource.createTask(makeTask(id: 't1', title: 'Comprar leche'));
      await datasource.createTask(makeTask(
          id: 't2',
          title: 'Estudiar Flutter',
          isCompleted: true,
          priority: TaskPriority.high));
      await datasource.createTask(makeTask(
          id: 't3', title: 'Llamar médico', category: 'Salud'));
    });

    test('returns all tasks with empty filter', () async {
      final result = await datasource.searchTasks(const TaskFilter());

      result.fold((_) => fail('Expected Right'), (tasks) {
        expect(tasks.length, 3);
      });
    });

    test('filters by keyword in title', () async {
      final result =
          await datasource.searchTasks(const TaskFilter(keyword: 'Flutter'));

      result.fold((_) => fail('Expected Right'), (tasks) {
        expect(tasks.length, 1);
        expect(tasks.first.title, 'Estudiar Flutter');
      });
    });

    test('filters by keyword case-insensitive', () async {
      final result =
          await datasource.searchTasks(const TaskFilter(keyword: 'leche'));

      result.fold((_) => fail('Expected Right'), (tasks) {
        expect(tasks.length, 1);
        expect(tasks.first.id, 't1');
      });
    });

    test('filters by isCompleted true — server-side query', () async {
      final result =
          await datasource.searchTasks(const TaskFilter(isCompleted: true));

      result.fold((_) => fail('Expected Right'), (tasks) {
        expect(tasks.every((t) => t.isCompleted), isTrue);
        expect(tasks.length, 1);
      });
    });

    test('filters by isCompleted false — server-side query', () async {
      final result =
          await datasource.searchTasks(const TaskFilter(isCompleted: false));

      result.fold((_) => fail('Expected Right'), (tasks) {
        expect(tasks.every((t) => !t.isCompleted), isTrue);
        expect(tasks.length, 2);
      });
    });

    test('filters by priority — server-side query', () async {
      final result = await datasource
          .searchTasks(const TaskFilter(priority: TaskPriority.high));

      result.fold((_) => fail('Expected Right'), (tasks) {
        expect(tasks.length, 1);
        expect(tasks.first.id, 't2');
      });
    });

    test('filters by category — server-side query', () async {
      final result =
          await datasource.searchTasks(const TaskFilter(category: 'Salud'));

      result.fold((_) => fail('Expected Right'), (tasks) {
        expect(tasks.length, 1);
        expect(tasks.first.id, 't3');
      });
    });

    test('combines server-side and in-memory filters', () async {
      final result = await datasource.searchTasks(
          const TaskFilter(isCompleted: false, keyword: 'médico'));

      result.fold((_) => fail('Expected Right'), (tasks) {
        expect(tasks.length, 1);
        expect(tasks.first.id, 't3');
      });
    });
  });

  group('network failure', () {
    late FirebaseTaskDatasource offlineDatasource;

    setUp(() {
      offlineDatasource = FirebaseTaskDatasource(
        firestore: fakeFirestore,
        auth: mockAuth,
        networkInfo: FakeNetworkInfo(connected: false),
      );
    });

    test('getAllTasks returns NetworkFailure when offline', () async {
      final result = await offlineDatasource.getAllTasks();
      expect(result, const Left(NetworkFailure()));
    });

    test('createTask returns NetworkFailure when offline', () async {
      final result = await offlineDatasource.createTask(makeTask());
      expect(result, const Left(NetworkFailure()));
    });

    test('updateTask returns NetworkFailure when offline', () async {
      final result = await offlineDatasource.updateTask(makeTask());
      expect(result, const Left(NetworkFailure()));
    });

    test('deleteTask returns NetworkFailure when offline', () async {
      final result = await offlineDatasource.deleteTask('any-id');
      expect(result, const Left(NetworkFailure()));
    });

    test('getTaskById returns NetworkFailure when offline', () async {
      final result = await offlineDatasource.getTaskById('any-id');
      expect(result, const Left(NetworkFailure()));
    });

    test('searchTasks returns NetworkFailure when offline', () async {
      final result =
          await offlineDatasource.searchTasks(const TaskFilter());
      expect(result, const Left(NetworkFailure()));
    });
  });
}
