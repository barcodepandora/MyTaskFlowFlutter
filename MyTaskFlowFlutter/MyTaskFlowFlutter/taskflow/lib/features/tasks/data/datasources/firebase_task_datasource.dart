import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart' hide Task;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/tasks/data/models/task_model.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/repositories/task_repository.dart';

class FirebaseTaskDatasource implements TaskRepository {
  FirebaseTaskDatasource({
    required FirebaseFirestore firestore,
    required fb.FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;

  String get _userId => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('tasks');

  @override
  Future<Either<Failure, List<Task>>> getAllTasks() async {
    try {
      final snap =
          await _col.where('userId', isEqualTo: _userId).get();
      final tasks = snap.docs
          .map((d) => TaskModel.fromFirestore(d.data(), d.id))
          .toList();
      return Right(tasks);
    } on FirebaseException catch (e) {
      return Left(StorageFailure(e.message ?? 'Firestore error'));
    }
  }

  @override
  Future<Either<Failure, Task>> getTaskById(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return const Left(TaskNotFoundFailure());
      return Right(TaskModel.fromFirestore(doc.data()!, doc.id));
    } on FirebaseException catch (e) {
      return Left(StorageFailure(e.message ?? 'Firestore error'));
    }
  }

  @override
  Future<Either<Failure, Task>> createTask(Task task) async {
    try {
      final model = TaskModel.fromEntity(task);
      await _col.doc(task.id).set(model.toFirestore(_userId));
      return Right(task);
    } on FirebaseException catch (e) {
      return Left(StorageFailure(e.message ?? 'Firestore error'));
    }
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    try {
      final doc = await _col.doc(task.id).get();
      if (!doc.exists) return const Left(TaskNotFoundFailure());
      final model = TaskModel.fromEntity(task);
      await _col.doc(task.id).update(model.toFirestore(_userId));
      return Right(task);
    } on FirebaseException catch (e) {
      return Left(StorageFailure(e.message ?? 'Firestore error'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return const Left(TaskNotFoundFailure());
      await _col.doc(id).delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(StorageFailure(e.message ?? 'Firestore error'));
    }
  }

  @override
  Future<Either<Failure, List<Task>>> searchTasks(TaskFilter filter) async {
    final result = await getAllTasks();
    return result.fold(
      Left.new,
      (tasks) {
        var filtered = tasks;

        if (filter.keyword != null && filter.keyword!.isNotEmpty) {
          final kw = filter.keyword!.toLowerCase();
          filtered = filtered
              .where((t) =>
                  t.title.toLowerCase().contains(kw) ||
                  t.description.toLowerCase().contains(kw))
              .toList();
        }
        if (filter.category != null) {
          filtered =
              filtered.where((t) => t.category == filter.category).toList();
        }
        if (filter.priority != null) {
          filtered =
              filtered.where((t) => t.priority == filter.priority).toList();
        }
        if (filter.isCompleted != null) {
          filtered = filtered
              .where((t) => t.isCompleted == filter.isCompleted)
              .toList();
        }
        if (filter.isOverdue == true) {
          filtered = filtered.where((t) => t.isOverdue).toList();
        }

        return Right(filtered);
      },
    );
  }
}
