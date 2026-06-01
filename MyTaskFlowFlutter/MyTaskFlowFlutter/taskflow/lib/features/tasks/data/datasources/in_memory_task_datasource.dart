import 'package:dartz/dartz.dart' hide Task;

import '../../../../core/error/failures.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_filter.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/repositories/task_repository.dart';

class InMemoryTaskDatasource implements TaskRepository {
  InMemoryTaskDatasource() {
    _tasks.addAll(_seedData());
  }

  final List<Task> _tasks = [];

  List<Task> _seedData() {
    final now = DateTime.now();
    return [
      Task(
        id: 'seed-1',
        title: 'Revisar correos',
        description: 'Leer y responder correos pendientes',
        dueDate: now.add(const Duration(days: 1)),
        category: 'Trabajo',
        priority: TaskPriority.high,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: 'seed-2',
        title: 'Hacer ejercicio',
        description: '30 minutos de cardio',
        dueDate: now.add(const Duration(hours: 3)),
        category: 'Salud',
        priority: TaskPriority.medium,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: 'seed-3',
        title: 'Estudiar Flutter',
        description: 'Completar módulo de Riverpod',
        dueDate: now.add(const Duration(days: 3)),
        category: 'Estudio',
        priority: TaskPriority.medium,
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: 'seed-4',
        title: 'Comprar víveres',
        description: 'Lista del supermercado semanal',
        dueDate: now.subtract(const Duration(days: 1)),
        category: 'Personal',
        priority: TaskPriority.low,
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 'seed-5',
        title: 'Llamar al médico',
        description: 'Agendar revisión anual',
        dueDate: now.subtract(const Duration(hours: 2)),
        category: 'Salud',
        priority: TaskPriority.high,
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Task(
        id: 'seed-6',
        title: 'Preparar presentación',
        description: 'Slides para reunión del lunes',
        dueDate: now.add(const Duration(days: 2)),
        category: 'Trabajo',
        priority: TaskPriority.high,
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  @override
  Future<Either<Failure, List<Task>>> getAllTasks() async =>
      Right(List.unmodifiable(_tasks));

  @override
  Future<Either<Failure, Task>> getTaskById(String id) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == id);
      return Right(task);
    } catch (_) {
      return const Left(TaskNotFoundFailure());
    }
  }

  @override
  Future<Either<Failure, Task>> createTask(Task task) async {
    _tasks.add(task);
    return Right(task);
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return const Left(TaskNotFoundFailure());
    _tasks[index] = task;
    return Right(task);
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return const Left(TaskNotFoundFailure());
    _tasks.removeAt(index);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Task>>> searchTasks(TaskFilter filter) async {
    var result = List<Task>.from(_tasks);

    if (filter.keyword != null && filter.keyword!.isNotEmpty) {
      final kw = filter.keyword!.toLowerCase();
      result = result
          .where((t) =>
              t.title.toLowerCase().contains(kw) ||
              t.description.toLowerCase().contains(kw))
          .toList();
    }

    if (filter.category != null) {
      result = result.where((t) => t.category == filter.category).toList();
    }

    if (filter.priority != null) {
      result = result.where((t) => t.priority == filter.priority).toList();
    }

    if (filter.isCompleted != null) {
      result =
          result.where((t) => t.isCompleted == filter.isCompleted).toList();
    }

    if (filter.isOverdue == true) {
      result = result.where((t) => t.isOverdue).toList();
    }

    return Right(result);
  }
}
