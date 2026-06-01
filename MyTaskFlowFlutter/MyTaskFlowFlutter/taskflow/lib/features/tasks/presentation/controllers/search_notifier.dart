import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';

import 'search_state.dart';

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState(filteredTasks: []));

  List<Task> _allTasks = [];

  void updateTasks(List<Task> tasks) {
    _allTasks = tasks;
    _applyFilters();
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query);
    _applyFilters();
  }

  void updateFilter(TaskFilter filter) {
    state = state.copyWith(filter: filter);
    _applyFilters();
  }

  void clearFilters() {
    state = SearchState(filteredTasks: _allTasks);
  }

  void _applyFilters() {
    var tasks = List<Task>.from(_allTasks);

    if (state.query.isNotEmpty) {
      final kw = state.query.toLowerCase();
      tasks = tasks
          .where((t) =>
              t.title.toLowerCase().contains(kw) ||
              t.description.toLowerCase().contains(kw))
          .toList();
    }

    if (state.filter.priority != null) {
      tasks = tasks.where((t) => t.priority == state.filter.priority).toList();
    }

    if (state.filter.isCompleted != null) {
      tasks =
          tasks.where((t) => t.isCompleted == state.filter.isCompleted).toList();
    }

    if (state.filter.isOverdue == true) {
      tasks = tasks.where((t) => t.isOverdue).toList();
    }

    state = state.copyWith(filteredTasks: tasks);
  }
}
