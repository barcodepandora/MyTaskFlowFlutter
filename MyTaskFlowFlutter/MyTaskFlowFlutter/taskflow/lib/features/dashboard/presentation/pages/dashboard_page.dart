import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow/features/auth/data/providers/auth_providers.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_state.dart';
import 'package:taskflow/features/dashboard/domain/entities/task_stats.dart';
import 'package:taskflow/features/dashboard/presentation/controllers/dashboard_providers.dart';
import 'package:taskflow/features/dashboard/presentation/controllers/dashboard_state.dart';
import 'package:taskflow/features/dashboard/presentation/widgets/completion_progress_bar.dart';
import 'package:taskflow/features/dashboard/presentation/widgets/recent_activity_list.dart';
import 'package:taskflow/features/dashboard/presentation/widgets/stats_card.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(dashboardNotifierProvider.notifier).loadDashboard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final greeting = _greeting(authState);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: switch (state) {
        DashboardLoading() =>
          const Center(child: CircularProgressIndicator()),
        DashboardLoaded(:final stats, :final recentTasks) =>
          _Loaded(greeting: greeting, stats: stats, recentTasks: recentTasks),
        DashboardError(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  key: const Key('dashboardRetryBtn'),
                  onPressed: () => ref
                      .read(dashboardNotifierProvider.notifier)
                      .loadDashboard(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        _ => const SizedBox(),
      },
    );
  }

  String _greeting(AuthState authState) {
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final name = user.displayName ?? user.email.split('@').first;
      return 'Hola, $name';
    }
    return 'Hola';
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.greeting,
    required this.stats,
    required this.recentTasks,
  });

  final String greeting;
  final TaskStats stats;
  final List<Task> recentTasks;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            _formattedDate(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Resumen',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              StatsCard(
                key: const Key('statsTotal'),
                label: 'Total',
                value: '${stats.totalTasks}',
                icon: Icons.checklist,
                color: Colors.blue,
              ),
              StatsCard(
                key: const Key('statsPending'),
                label: 'Pendientes',
                value: '${stats.pendingTasks}',
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              StatsCard(
                key: const Key('statsCompleted'),
                label: 'Completadas',
                value: '${stats.completedTasks}',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
              StatsCard(
                key: const Key('statsOverdue'),
                label: 'Vencidas',
                value: '${stats.overdueTasks}',
                icon: Icons.warning_amber,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Progreso',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          CompletionProgressBar(value: stats.completionRate),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Actividad reciente',
                  style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                key: const Key('verTodasBtn'),
                onPressed: () => context.go('/tasks'),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RecentActivityList(tasks: recentTasks),
        ],
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${now.day} ${months[now.month]} ${now.year}';
  }
}
