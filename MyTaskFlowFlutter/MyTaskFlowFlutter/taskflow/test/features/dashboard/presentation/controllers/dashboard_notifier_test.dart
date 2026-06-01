import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/dashboard/domain/entities/task_stats.dart';
import 'package:taskflow/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:taskflow/features/dashboard/domain/usecases/get_recent_activity_usecase.dart';
import 'package:taskflow/features/dashboard/presentation/controllers/dashboard_notifier.dart';
import 'package:taskflow/features/dashboard/presentation/controllers/dashboard_state.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';

class MockGetDashboardStatsUseCase extends Mock
    implements GetDashboardStatsUseCase {}

class MockGetRecentActivityUseCase extends Mock
    implements GetRecentActivityUseCase {}

Task _task(String id) {
  final now = DateTime.now();
  return Task(
    id: id,
    title: 'Task $id',
    description: '',
    dueDate: now.add(const Duration(days: 1)),
    category: 'Work',
    priority: TaskPriority.medium,
    isCompleted: false,
    createdAt: now,
    updatedAt: now,
  );
}

const _sampleStats = TaskStats(
  totalTasks: 2,
  completedTasks: 1,
  pendingTasks: 1,
  overdueTasks: 0,
);

void main() {
  late MockGetDashboardStatsUseCase getStats;
  late MockGetRecentActivityUseCase getActivity;
  late DashboardNotifier notifier;

  setUp(() {
    getStats = MockGetDashboardStatsUseCase();
    getActivity = MockGetRecentActivityUseCase();
    notifier = DashboardNotifier(
      getDashboardStats: getStats,
      getRecentActivity: getActivity,
    );
  });

  test('initial state is DashboardInitial', () {
    expect(notifier.state, isA<DashboardInitial>());
  });

  group('loadDashboard', () {
    test('emits Loading then Loaded on success', () async {
      when(() => getStats()).thenAnswer((_) async => const Right(_sampleStats));
      when(() => getActivity(maxItems: any(named: 'maxItems')))
          .thenAnswer((_) async => Right([_task('1')]));

      final states = <DashboardState>[];
      notifier.addListener(states.add, fireImmediately: false);

      await notifier.loadDashboard();

      expect(states[0], isA<DashboardLoading>());
      expect(states[1], isA<DashboardLoaded>());
      final loaded = states[1] as DashboardLoaded;
      expect(loaded.stats, _sampleStats);
      expect(loaded.recentTasks.length, 1);
    });

    test('emits DashboardError when getStats fails', () async {
      when(() => getStats())
          .thenAnswer((_) async => const Left(StorageFailure('stats error')));

      await notifier.loadDashboard();

      expect(notifier.state, isA<DashboardError>());
      expect((notifier.state as DashboardError).message, 'stats error');
    });

    test('emits DashboardError when getActivity fails', () async {
      when(() => getStats()).thenAnswer((_) async => const Right(_sampleStats));
      when(() => getActivity(maxItems: any(named: 'maxItems')))
          .thenAnswer((_) async => const Left(StorageFailure('activity error')));

      await notifier.loadDashboard();

      expect(notifier.state, isA<DashboardError>());
    });
  });

  test('refresh calls loadDashboard again', () async {
    when(() => getStats()).thenAnswer((_) async => const Right(_sampleStats));
    when(() => getActivity(maxItems: any(named: 'maxItems')))
        .thenAnswer((_) async => const Right([]));

    await notifier.refresh();

    verify(() => getStats()).called(1);
    verify(() => getActivity(maxItems: any(named: 'maxItems'))).called(1);
  });
}
