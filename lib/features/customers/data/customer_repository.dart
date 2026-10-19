import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_handler.dart';
import '../../../shared/models/paginated_response.dart';
import '../domain/customer_address_models.dart';
import '../domain/customer_models.dart';
import '../domain/customer_note_models.dart';

class CustomerRepository {
  Future<Dio> _getDio() async => (await DioClient.getInstance()).dio;

  Future<PaginatedResponse<CustomerLean>> getCustomers({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(
        ApiEndpoints.customers,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CustomerLean.fromJson(json),
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Search customers by name or phone.
  /// Backend: POST /customers/search (POST instead of GET so phone numbers
  /// don't end up in URLs/logs).
  /// Returns raw maps with at least `id`, `name`, `phone` keys.
  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        '${ApiEndpoints.customers}/search',
        data: {'query': query},
      );
      final list = response.data as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CustomerDetail> updateCustomer(
    String id,
    CustomerUpdateInput input,
  ) async {
    try {
      final dio = await _getDio();
      final response = await dio.put(
        '${ApiEndpoints.customers}/$id',
        data: input.toJson(),
      );
      return CustomerDetail.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CustomerDetail> getCustomer(String id) async {
    try {
      final dio = await _getDio();
      final response =
          await dio.get('${ApiEndpoints.customers}/$id');
      return CustomerDetail.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// PATCH /customers/:id/toggles — block / require-prepayment / cod.
  /// At least one field must be non-null. Returns the refreshed
  /// CustomerDetail.
  Future<CustomerDetail> updateToggles(
    String id, {
    bool? isBlocked,
    String? blockReason,
    bool? requirePrepayment,
    bool? codEnabled,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.patch(
        ApiEndpoints.customerToggles(id),
        data: {
          if (isBlocked != null) 'isBlocked': isBlocked,
          // blockReason can be set explicitly to null to clear it.
          // We send the key whenever isBlocked is being changed OR
          // when the caller passed a non-null reason. Sending it as
          // a JSON null clears the column; omitting it preserves.
          if (blockReason != null) 'blockReason': blockReason,
          if (requirePrepayment != null) 'requirePrepayment': requirePrepayment,
          if (codEnabled != null) 'codEnabled': codEnabled,
        },
      );
      return CustomerDetail.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// PATCH /customers/:id/profile — birthday + preferredContactChannel + tags.
  /// `birthday: null` (passed via the [clearBirthday] sentinel) clears it.
  /// `tags` is REPLACE semantics — pass [] to clear all.
  Future<CustomerDetail> updateProfile(
    String id, {
    DateTime? birthday,
    bool clearBirthday = false,
    ContactChannel? preferredContactChannel,
    List<String>? tags,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.patch(
        ApiEndpoints.customerProfile(id),
        data: {
          if (clearBirthday)
            'birthday': null
          else if (birthday != null)
            'birthday':
                '${birthday.year.toString().padLeft(4, '0')}-${birthday.month.toString().padLeft(2, '0')}-${birthday.day.toString().padLeft(2, '0')}',
          if (preferredContactChannel != null)
            'preferredContactChannel': preferredContactChannel.wire,
          if (tags != null) 'tags': tags,
        },
      );
      return CustomerDetail.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Notes ──────────────────────────────────────────────
  Future<List<CustomerNote>> listNotes(String customerId) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(ApiEndpoints.customerNotes(customerId));
      final body = response.data as Map<String, dynamic>;
      final raw = body['notes'] as List<dynamic>? ?? const [];
      return raw
          .map((e) => CustomerNote.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CustomerNote> createNote({
    required String customerId,
    required String content,
    bool isPinned = false,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.customerNotes(customerId),
        data: {
          'content': content,
          if (isPinned) 'isPinned': true,
        },
      );
      return CustomerNote.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CustomerNote> updateNote({
    required String customerId,
    required String noteId,
    String? content,
    bool? isPinned,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.patch(
        ApiEndpoints.customerNote(customerId, noteId),
        data: {
          if (content != null) 'content': content,
          if (isPinned != null) 'isPinned': isPinned,
        },
      );
      return CustomerNote.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteNote({
    required String customerId,
    required String noteId,
  }) async {
    try {
      final dio = await _getDio();
      await dio.delete(ApiEndpoints.customerNote(customerId, noteId));
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Addresses ──────────────────────────────────────────
  Future<List<CustomerAddress>> listAddresses(String customerId) async {
    try {
      final dio = await _getDio();
      final response =
          await dio.get(ApiEndpoints.customerAddresses(customerId));
      final body = response.data as Map<String, dynamic>;
      final raw = body['addresses'] as List<dynamic>? ?? const [];
      return raw
          .map((e) => CustomerAddress.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CustomerAddress> createAddress({
    required String customerId,
    required String addressLine,
    required String city,
    required String governorate,
    String? label,
    String? deliveryNotes,
    bool isDefault = false,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.customerAddresses(customerId),
        data: {
          if (label != null) 'label': label,
          'addressLine': addressLine,
          'city': city,
          'governorate': governorate,
          if (deliveryNotes != null) 'deliveryNotes': deliveryNotes,
          if (isDefault) 'isDefault': true,
        },
      );
      return CustomerAddress.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// PATCH /customers/:id/addresses/:addrId — content-only update.
  /// `isDefault` lives on the dedicated [setDefaultAddress] endpoint.
  /// Pass [clearLabel] / [clearDeliveryNotes] to send a JSON null.
  Future<CustomerAddress> updateAddress({
    required String customerId,
    required String addressId,
    String? label,
    bool clearLabel = false,
    String? addressLine,
    String? city,
    String? governorate,
    String? deliveryNotes,
    bool clearDeliveryNotes = false,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.patch(
        ApiEndpoints.customerAddress(customerId, addressId),
        data: {
          if (clearLabel)
            'label': null
          else if (label != null)
            'label': label,
          if (addressLine != null) 'addressLine': addressLine,
          if (city != null) 'city': city,
          if (governorate != null) 'governorate': governorate,
          if (clearDeliveryNotes)
            'deliveryNotes': null
          else if (deliveryNotes != null)
            'deliveryNotes': deliveryNotes,
        },
      );
      return CustomerAddress.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteAddress({
    required String customerId,
    required String addressId,
  }) async {
    try {
      final dio = await _getDio();
      await dio.delete(ApiEndpoints.customerAddress(customerId, addressId));
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CustomerAddress> setDefaultAddress({
    required String customerId,
    required String addressId,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.patch(
        ApiEndpoints.customerAddressDefault(customerId, addressId),
      );
      return CustomerAddress.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// PATCH /customers/:id/risk — riskLevel + optional riskReason.
  /// Passing `clearReason: true` clears the reason.
  Future<CustomerDetail> updateRisk(
    String id, {
    required RiskLevel riskLevel,
    String? riskReason,
    bool clearReason = false,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.patch(
        ApiEndpoints.customerRisk(id),
        data: {
          'riskLevel': riskLevel.wire,
          if (clearReason)
            'riskReason': null
          else if (riskReason != null)
            'riskReason': riskReason,
        },
      );
      return CustomerDetail.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}