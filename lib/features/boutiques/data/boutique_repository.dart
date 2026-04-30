import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_handler.dart';
import '../domain/boutique_models.dart';
import '../domain/boutique_patch_input.dart';

class BoutiqueRepository {
  Future<Dio> _getDio() async => (await DioClient.getInstance()).dio;

  /// GET /boutiques/current
  Future<Boutique> getCurrent() async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/boutiques/current');
      return Boutique.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// GET /boutiques
  Future<List<Boutique>> list() async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/boutiques');
      final data =
          (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return data
          .map((e) => Boutique.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// PATCH /boutiques/current
  Future<Boutique> update(BoutiquePatchInput patch) async {
    try {
      final dio = await _getDio();
      final response = await dio.patch(
        '/boutiques/current',
        data: patch.toJsonNonNull(),
      );
      return Boutique.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// POST /boutiques/current/logo
  Future<String> uploadLogo(XFile file) async {
    try {
      final dio = await _getDio();
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name.isNotEmpty ? file.name : 'logo.png',
        ),
      });
      final response = await dio.post('/boutiques/current/logo', data: formData);
      return (response.data as Map<String, dynamic>)['logoUrl'] as String;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
