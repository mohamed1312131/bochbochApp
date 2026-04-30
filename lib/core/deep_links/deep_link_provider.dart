import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../router.dart';
import 'deep_link_service.dart';

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final router = ref.watch(routerProvider);
  final service = DeepLinkService(router: router);
  ref.onDispose(service.dispose);
  return service;
});
