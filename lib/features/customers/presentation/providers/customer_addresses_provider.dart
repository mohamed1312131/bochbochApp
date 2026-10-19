import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/customer_address_models.dart';
import 'customer_provider.dart';

/// Owns the in-flight list of addresses for one customer.
/// Mutations apply optimistically and roll back on failure so the
/// caller can surface a snackbar via the rethrown exception.
final customerAddressesProvider = AsyncNotifierProvider.autoDispose
    .family<CustomerAddressesNotifier, List<CustomerAddress>, String>(
  CustomerAddressesNotifier.new,
);

class CustomerAddressesNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<CustomerAddress>, String> {
  String get customerId => arg;

  @override
  Future<List<CustomerAddress>> build(String customerId) {
    return ref.read(customerRepositoryProvider).listAddresses(customerId);
  }

  /// Default first, then createdAt DESC. Mirrors the backend ORDER BY.
  List<CustomerAddress> _sorted(Iterable<CustomerAddress> addrs) {
    final out = [...addrs];
    out.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return out;
  }

  Future<void> create({
    required String addressLine,
    required String city,
    required String governorate,
    String? label,
    String? deliveryNotes,
    bool isDefault = false,
  }) async {
    final current = state.valueOrNull ?? const <CustomerAddress>[];

    final now = DateTime.now();
    final optimistic = CustomerAddress(
      id: 'pending-${now.microsecondsSinceEpoch}',
      customerId: customerId,
      label: label,
      addressLine: addressLine,
      city: city,
      governorate: governorate,
      deliveryNotes: deliveryNotes,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
    final next = [
      ...current.map(
        (a) => isDefault && a.isDefault ? a.copyWith(isDefault: false) : a,
      ),
      optimistic,
    ];
    state = AsyncData(_sorted(next));

    try {
      final created =
          await ref.read(customerRepositoryProvider).createAddress(
                customerId: customerId,
                addressLine: addressLine,
                city: city,
                governorate: governorate,
                label: label,
                deliveryNotes: deliveryNotes,
                isDefault: isDefault,
              );
      final replaced = (state.valueOrNull ?? const <CustomerAddress>[])
          .map((a) => a.id == optimistic.id ? created : a)
          .toList();
      state = AsyncData(_sorted(replaced));
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Content edit (no isDefault — use [setDefault]). Pass
  /// `clearLabel: true` / `clearDeliveryNotes: true` to send null.
  Future<void> edit(
    String addressId, {
    String? label,
    bool clearLabel = false,
    String? addressLine,
    String? city,
    String? governorate,
    String? deliveryNotes,
    bool clearDeliveryNotes = false,
  }) async {
    final current = state.valueOrNull ?? const <CustomerAddress>[];

    final next = current.map((a) {
      if (a.id != addressId) return a;
      return a.copyWith(
        label: clearLabel ? null : (label ?? a.label),
        addressLine: addressLine,
        city: city,
        governorate: governorate,
        deliveryNotes:
            clearDeliveryNotes ? null : (deliveryNotes ?? a.deliveryNotes),
        updatedAt: DateTime.now(),
      );
    }).toList();
    state = AsyncData(_sorted(next));

    try {
      final fresh =
          await ref.read(customerRepositoryProvider).updateAddress(
                customerId: customerId,
                addressId: addressId,
                label: label,
                clearLabel: clearLabel,
                addressLine: addressLine,
                city: city,
                governorate: governorate,
                deliveryNotes: deliveryNotes,
                clearDeliveryNotes: clearDeliveryNotes,
              );
      final merged = (state.valueOrNull ?? const <CustomerAddress>[])
          .map((a) => a.id == addressId ? fresh : a)
          .toList();
      state = AsyncData(_sorted(merged));
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> setDefault(String addressId) async {
    final current = state.valueOrNull ?? const <CustomerAddress>[];

    final next = current
        .map((a) => a.copyWith(isDefault: a.id == addressId))
        .toList();
    state = AsyncData(_sorted(next));

    try {
      final fresh =
          await ref.read(customerRepositoryProvider).setDefaultAddress(
                customerId: customerId,
                addressId: addressId,
              );
      final merged = (state.valueOrNull ?? const <CustomerAddress>[])
          .map((a) => a.id == addressId ? fresh : a)
          .toList();
      state = AsyncData(_sorted(merged));
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> delete(String addressId) async {
    final current = state.valueOrNull ?? const <CustomerAddress>[];
    state = AsyncData(
      current.where((a) => a.id != addressId).toList(),
    );

    try {
      await ref.read(customerRepositoryProvider).deleteAddress(
            customerId: customerId,
            addressId: addressId,
          );
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
