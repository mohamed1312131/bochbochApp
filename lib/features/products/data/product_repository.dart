import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_handler.dart';
import '../../../shared/models/paginated_response.dart';
import '../domain/product_models.dart';

class ProductRepository {
  Future<Dio> _getDio() async => (await DioClient.getInstance()).dio;

  // ── List ───────────────────────────────────────────────
  Future<PaginatedResponse<ProductLean>> getProducts({
    String? cursor,
    int limit = 20,
    String? name,
    String? category,
    bool? isActive,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(
        ApiEndpoints.products,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
          if (name != null) 'name': name,
          if (category != null) 'category': category,
          if (isActive != null) 'isActive': isActive,
        },
      );
      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ProductLean.fromJson(json),
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Detail ─────────────────────────────────────────────
  Future<Product> getProduct(String id) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(ApiEndpoints.product(id));
      return Product.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Create ─────────────────────────────────────────────
  Future<Product> createProduct({
    required String name,
    required int baseCostPrice,
    required int baseSellPrice,
    required int initialStock,
    String? description,
    String? category,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.products,
        data: {
          'name': name,
          'baseCostPrice': baseCostPrice,
          'baseSellPrice': baseSellPrice,
          'initialStock': initialStock,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      return Product.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Update ─────────────────────────────────────────────
  Future<Product> updateProduct(
    String id, {
    String? name,
    String? description,
    String? category,
    int? baseCostPrice,
    int? baseSellPrice,
    bool? isActive,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.put(
        ApiEndpoints.product(id),
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (category != null) 'category': category,
          if (baseCostPrice != null) 'baseCostPrice': baseCostPrice,
          if (baseSellPrice != null) 'baseSellPrice': baseSellPrice,
          if (isActive != null) 'isActive': isActive,
        },
      );
      return Product.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Quick Stock ────────────────────────────────────────
  Future<void> updateStock(
    String id, {
    required int quantity,
    required String variantUpdatedAt,
  }) async {
    try {
      final dio = await _getDio();
      await dio.patch(
        ApiEndpoints.productStock(id),
        data: {
          'quantity': quantity,
          'variantUpdatedAt': variantUpdatedAt,
        },
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Delete ─────────────────────────────────────────────
  Future<void> deleteProduct(String id) async {
    try {
      final dio = await _getDio();
      await dio.delete(ApiEndpoints.product(id));
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Upload Image ───────────────────────────────────────
  Future<Map<String, String>> uploadImage(String filePath) async {
    try {
      final dio = await _getDio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await dio.post(
        ApiEndpoints.imageUpload,
        data: formData,
      );
      final data = response.data as Map<String, dynamic>;
      return {
        'url': data['url'] as String,
        'cloudinaryPublicId': data['cloudinaryPublicId'] as String,
      };
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Attach Image to Product ────────────────────────────
  Future<void> attachImage(
    String productId, {
    required String cloudinaryPublicId,
    required String url,
    bool isPrimary = true,
    String? altText,
  }) async {
    try {
      final dio = await _getDio();
      await dio.post(
        '/products/$productId/images',
        data: {
          'cloudinaryPublicId': cloudinaryPublicId,
          'url': url,
          'isPrimary': isPrimary,
          if (altText != null) 'altText': altText,
        },
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}