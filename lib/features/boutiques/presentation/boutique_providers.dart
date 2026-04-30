import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/boutique_repository.dart';
import '../domain/boutique_models.dart';

/// Provides BoutiqueRepository instance. Stateless — repo internally
/// resolves the singleton DioClient on each call.
final boutiqueRepositoryProvider = Provider<BoutiqueRepository>((ref) {
  return BoutiqueRepository();
});

/// Fetches the current boutique. autoDispose so it refetches when the
/// user returns to a screen depending on it (boutique data may change
/// during onboarding in Stage 5E).
final currentBoutiqueProvider = FutureProvider.autoDispose<Boutique>((ref) async {
  final repo = ref.watch(boutiqueRepositoryProvider);
  return repo.getCurrent();
});
