import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profit_repository.dart';
import '../../domain/profit_models.dart';

final profitRepositoryProvider = Provider<ProfitRepository>(
  (_) => ProfitRepository(),
);

final selectedPeriodProvider =
    StateProvider.autoDispose<String>((ref) => 'month');

final profitSummaryProvider =
    FutureProvider.autoDispose.family<ProfitSummary, String>(
  (ref, period) =>
      ref.read(profitRepositoryProvider).getSummary(period: period),
);

final productProfitProvider =
    FutureProvider.autoDispose.family<List<ProductProfit>, String>(
  (ref, period) =>
      ref.read(profitRepositoryProvider).getByProduct(period: period),
);

final profitTrendProvider =
    FutureProvider.autoDispose.family<ProfitTrend, String>(
  (ref, period) =>
      ref.read(profitRepositoryProvider).getTrend(period: period),
);
