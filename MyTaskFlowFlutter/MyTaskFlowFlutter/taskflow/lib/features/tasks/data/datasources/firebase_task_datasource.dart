import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart' hide Task;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/core/network/network_info.dart';
import 'package:taskflow/features/tasks/data/models/task_model.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/repositories/task_repository.dart';

class FirebaseTaskDatasource implements TaskRepository {
  FirebaseTaskDatasource({
    required FirebaseFirestore firestore,
    required fb.FirebaseAuth auth,
    required NetworkInfo networkInfo,
  })  : _firestore = firestore,
        _auth = auth,
        _networkInfo = networkInfo;

  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;
  final NetworkInfo _networkInfo;

  String get _userId => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('tasks');

  Future<Either<Failure, T>> _withConnectivity<T>(
    Future<Either<Failure, T>> Function() operation,
  ) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    return operation();
  }

  @override
  Future<Either<Failure, List<Task>>> getAllTasks() {
    return _withConnectivity(() async {
      try {
        final snap = await _col.where('userId', isEqualTo: _userId).get();
        final tasks = snap.docs
            .map((d) => TaskModel.fromFirestore(d.data(), d.id))
            .toList();
        return Right(tasks);
      } on FirebaseException catch (e) {
        return Left(StorageFailure(e.message ?? 'Firestore error'));
      }
    });
  }

  @override
  Future<Either<Failure, Task>> getTaskById(String id) {
    return _withConnectivity(() async {
      try {
        final doc = await _col.doc(id).get();
        if (!doc.exists) return const Left(TaskNotFoundFailure());
        return Right(TaskModel.fromFirestore(doc.data()!, doc.id));
      } on FirebaseException catch (e) {
        return Left(StorageFailure(e.message ?? 'Firestore error'));
      }
    });
  }

  @override
  Future<Either<Failure, Task>> createTask(Task task) {
    return _withConnectivity(() async {
      try {
        final model = TaskModel.fromEntity(task);
        await _col.doc(task.id).set(model.toFirestore(_userId));
        return Right(task);
      } on FirebaseException catch (e) {
        return Left(StorageFailure(e.message ?? 'Firestore error'));
      }
    });
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) {
    return _withConnectivity(() async {
      try {
        final doc = await _col.doc(task.id).get();
        if (!doc.exists) return const Left(TaskNotFoundFailure());
        final model = TaskModel.fromEntity(task);
        await _col.doc(task.id).update(model.toFirestore(_userId));
        return Right(task);
      } on FirebaseException catch (e) {
        return Left(StorageFailure(e.message ?? 'Firestore error'));
      }
    });
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) {
    return _withConnectivity(() async {
      try {
        final doc = await _col.doc(id).get();
        if (!doc.exists) return const Left(TaskNotFoundFailure());
        await _col.doc(id).delete();
        return const Right(null);
      } on FirebaseException catch (e) {
        return Left(StorageFailure(e.message ?? 'Firestore error'));
      }
    });
  }

  @override
  Future<Either<Failure, List<Task>>> searchTasks(TaskFilter filter) {
    return _withConnectivity(() async {
      try {
        // Push equality filters to Firestore; keep keyword/isOverdue in memory
        // (Firestore doesn't support substring search or computed fields).
        // Composite indexes are auto-created by Firebase on first use.
        Query<Map<String, dynamic>> query =
            _col.where('userId', isEqualTo: _userId);

        if (filter.isCompleted != null) {
          query = query.where('isCompleted', isEqualTo: filter.isCompleted);
        }
        if (filter.priority != null) {
          query = query.where('priority', isEqualTo: filter.priority!.name);
        }
        if (filter.category != null) {
          query = query.where('category', isEqualTo: filter.category);
        }

        final snap = await query.get();
        var tasks = snap.docs
            .map((d) => TaskModel.fromFirestore(d.data(), d.id))
            .toList();

        if (filter.keyword != null && filter.keyword!.isNotEmpty) {
          final kw = filter.keyword!.toLowerCase();
          tasks = tasks
              .where((t) =>
                  t.title.toLowerCase().contains(kw) ||
                  t.description.toLowerCase().contains(kw))
              .toList();
        }
        if (filter.isOverdue == true) {
          tasks = tasks.where((t) => t.isOverdue).toList();
        }

        return Right(tasks);
      } on FirebaseException catch (e) {
        return Left(StorageFailure(e.message ?? 'Firestore error'));
      }
    });
  }
}
