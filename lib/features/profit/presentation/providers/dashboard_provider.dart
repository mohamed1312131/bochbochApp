import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

final dashboardProvider =
    FutureProvider.autoDispose<DashboardData>((ref) async {
  return ref.read(dashboardRepositoryProvider).getDashboard();
});