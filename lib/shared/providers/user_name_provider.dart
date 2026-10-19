import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Reads the authenticated user's full name from secure storage.
/// Used for displaying the user-avatar initial across screens.
final userNameProvider = FutureProvider.autoDispose<String>((ref) async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  return await storage.read(key: 'user_full_name') ?? '';
});
