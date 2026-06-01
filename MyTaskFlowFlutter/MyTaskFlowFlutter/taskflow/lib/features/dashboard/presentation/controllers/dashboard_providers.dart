import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:taskflow/features/dashboard/domain/usecases/get_recent_activity_usecase.dart';
import 'package:taskflow/features/dashboard/presentation/controllers/dashboard_notifier.dart';
import 'package:taskflow/features/dashboard/presentation/controllers/dashboard_state.dart';
import 'package:taskflow/features/tasks/data/providers/tasks_providers.dart';

final getDashboardStatsUseCaseProvider = Provider<GetDashboardStatsUseCase>(
  (ref) => GetDashboardStatsUseCase(ref.watch(taskRepositoryProvider)),
);

final getRecentActivityUseCaseProvider = Provider<GetRecentActivityUseCase>(
  (ref) => GetRecentActivityUseCase(ref.watch(taskRepositoryProvider)),
);

final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(
    getDashboardStats: ref.watch(getDashboardStatsUseCaseProvider),
    getRecentActivity: ref.watch(getRecentActivityUseCaseProvider),
  ),
);
