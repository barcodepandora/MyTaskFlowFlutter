import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/core/utils/failure_mapper.dart';
import 'package:taskflow/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:taskflow/features/dashboard/domain/usecases/get_recent_activity_usecase.dart';

import 'dashboard_state.dart';

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier({
    required GetDashboardStatsUseCase getDashboardStats,
    required GetRecentActivityUseCase getRecentActivity,
  })  : _getDashboardStats = getDashboardStats,
        _getRecentActivity = getRecentActivity,
        super(const DashboardInitial());

  final GetDashboardStatsUseCase _getDashboardStats;
  final GetRecentActivityUseCase _getRecentActivity;

  Future<void> loadDashboard() async {
    state = const DashboardLoading();

    final statsResult = await _getDashboardStats();
    if (statsResult.isLeft()) {
      state = DashboardError(
          statsResult.fold((f) => mapFailureToMessage(f), (_) => ''));
      return;
    }

    final activityResult = await _getRecentActivity();
    if (activityResult.isLeft()) {
      state = DashboardError(
          activityResult.fold((f) => mapFailureToMessage(f), (_) => ''));
      return;
    }

    state = DashboardLoaded(
      stats: statsResult.getOrElse(() => throw StateError('unreachable')),
      recentTasks: activityResult.getOrElse(() => []),
    );
  }

  Future<void> refresh() => loadDashboard();
}
