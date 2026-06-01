import 'package:equatable/equatable.dart';
import 'package:taskflow/features/dashboard/domain/entities/task_stats.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();

  @override
  List<Object?> get props => [];
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();

  @override
  List<Object?> get props => [];
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({required this.stats, required this.recentTasks});

  final TaskStats stats;
  final List<Task> recentTasks;

  @override
  List<Object?> get props => [stats, recentTasks];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
