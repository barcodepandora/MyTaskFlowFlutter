import 'package:equatable/equatable.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';

class SearchState extends Equatable {
  const SearchState({
    required this.filteredTasks,
    this.query = '',
    this.filter = const TaskFilter(),
  });

  final List<Task> filteredTasks;
  final String query;
  final TaskFilter filter;

  SearchState copyWith({
    List<Task>? filteredTasks,
    String? query,
    TaskFilter? filter,
  }) {
    return SearchState(
      filteredTasks: filteredTasks ?? this.filteredTasks,
      query: query ?? this.query,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [filteredTasks, query, filter];
}
