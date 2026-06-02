import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/data/providers/auth_providers.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';
import 'package:taskflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_state.dart';
import 'package:taskflow/features/dashboard/domain/entities/task_stats.dart';
import 'package:taskflow/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:taskflow/features/dashboard/domain/usecases/get_recent_activity_usecase.dart';
import 'package:taskflow/features/dashboard/presentation/controllers/dashboard_notifier.dart';
import 'package:taskflow/features/dashboard/presentation/controllers/dashboard_providers.dart';
import 'package:taskflow/features/dashboard/presentation/controllers/dashboard_state.dart';
import 'package:taskflow/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:taskflow/features/dashboard/presentation/widgets/completion_progress_bar.dart';
import 'package:taskflow/features/dashboard/presentation/widgets/stats_card.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow/features/tasks/domain/repositories/task_repository.dart';

// ---------- Fake AuthRepository ----------
class _FakeAuthRepo implements AuthRepository {
  @override
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword(
          String e, String p) async =>
      const Left(InvalidCredentialsFailure());
  @override
  Future<Either<Failure, void>> signOut() async => const Right(null);
  @override
  Stream<AuthUser> get authStateChanges => const Stream.empty();
}

// ---------- Fake TaskRepository ----------
class _FakeTaskRepo implements TaskRepository {
  @override
  Future<Either<Failure, List<Task>>> getAllTasks() async => const Right([]);
  @override
  Future<Either<Failure, Task>> getTaskById(String id) async =>
      const Left(TaskNotFoundFailure());
  @override
  Future<Either<Failure, Task>> createTask(Task task) async => Right(task);
  @override
  Future<Either<Failure, Task>> updateTask(Task task) async => Right(task);
  @override
  Future<Either<Failure, void>> deleteTask(String id) async =>
      const Right(null);
  @override
  Future<Either<Failure, List<Task>>> searchTasks(TaskFilter f) async =>
      const Right([]);
}

// ---------- Fake DashboardNotifier (fixed state) ----------
class _FakeDashboardNotifier extends DashboardNotifier {
  _FakeDashboardNotifier(DashboardState initial)
      : super(
          getDashboardStats: GetDashboardStatsUseCase(_FakeTaskRepo()),
          getRecentActivity: GetRecentActivityUseCase(_FakeTaskRepo()),
        ) {
    state = initial;
  }

  @override
  Future<void> loadDashboard() async {}
}

// ---------- Fake AuthNotifier (always authenticated) ----------
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier()
      : super(
          signInUseCase: SignInUseCase(_FakeAuthRepo()),
          signOutUseCase: SignOutUseCase(_FakeAuthRepo()),
        ) {
    state = const AuthAuthenticated(
      AuthUser(uid: 'u1', email: 'test@taskflow.com'),
    );
  }
}

// ---------- Sample data ----------
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

const _stats = TaskStats(
  totalTasks: 5,
  completedTasks: 2,
  pendingTasks: 3,
  overdueTasks: 1,
);

// ---------- Widget builder ----------
Widget _wrap(DashboardState initialState) {
  return ProviderScope(
    overrides: [
      dashboardNotifierProvider
          .overrideWith((ref) => _FakeDashboardNotifier(initialState)),
      authNotifierProvider.overrideWith((ref) => _FakeAuthNotifier()),
    ],
    child: MaterialApp.router(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      routerConfig: GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
          GoRoute(path: '/tasks', builder: (_, _) => const Scaffold(body: Text('tasks'))),
        ],
      ),
    ),
  );
}

// ---------- Tests ----------
void main() {
  testWidgets('Muestra loading cuando estado es DashboardLoading',
      (tester) async {
    await tester.pumpWidget(_wrap(const DashboardLoading()));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Muestra saludo con nombre de usuario', (tester) async {
    await tester.pumpWidget(
        _wrap(const DashboardLoaded(stats: _stats, recentTasks: [])));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hola'), findsOneWidget);
  });

  testWidgets(
      'Muestra 4 StatsCards (total, pendientes, completadas, vencidas)',
      (tester) async {
    await tester.pumpWidget(
        _wrap(const DashboardLoaded(stats: _stats, recentTasks: [])));
    await tester.pumpAndSettle();
    expect(find.byType(StatsCard), findsNWidgets(4));
  });

  testWidgets('Muestra CompletionProgressBar', (tester) async {
    await tester.pumpWidget(
        _wrap(const DashboardLoaded(stats: _stats, recentTasks: [])));
    await tester.pumpAndSettle();
    expect(find.byType(CompletionProgressBar), findsOneWidget);
  });

  testWidgets('Muestra RecentActivityList con máx 5 items', (tester) async {
    final tasks = List.generate(5, (i) => _task('$i'));
    await tester.pumpWidget(
        _wrap(DashboardLoaded(stats: _stats, recentTasks: tasks)));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(5));
  });

  testWidgets('Tap en "Ver todas" navega a /tasks', (tester) async {
    await tester.pumpWidget(
        _wrap(const DashboardLoaded(stats: _stats, recentTasks: [])));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('verTodasBtn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('verTodasBtn')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('tasks'), findsOneWidget);
  });
}
