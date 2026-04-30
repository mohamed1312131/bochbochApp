import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/goal_repository.dart';
import '../domain/goal_progress_models.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

/// Active goal for the current user, or null if none. autoDispose so it
/// refetches when the home screen re-mounts; invalidate after createGoal.
final activeGoalProvider =
    FutureProvider.autoDispose<GoalWithProgress?>((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.getActiveGoal();
});
