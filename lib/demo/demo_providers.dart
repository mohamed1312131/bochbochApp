import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_store.dart';

/// One store per ProviderScope. Refreshing the browser restores the original
/// curated scenario, and the in-app reset action calls [DemoStore.reset].
final demoStoreProvider = Provider<DemoStore>((ref) => DemoStore());
