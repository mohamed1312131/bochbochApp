// ─── Manual setup required before this works on device ──────────────────────
//
// iOS:
//   - Add a CFBundleURLTypes entry to ios/Runner/Info.plist using the
//     "REVERSED_CLIENT_ID" value from the iOS OAuth client in the Google
//     Cloud Console (or from the GoogleService-Info.plist if Firebase is
//     used). Without it, Google account picker silently fails to open.
//
// Android:
//   - Place google-services.json in android/app/ (download from Firebase
//     Console → project settings → SDK setup → Android).
//   - Register the debug keystore SHA-1 fingerprint on the Android OAuth
//     client in Google Cloud Console. Get it via:
//       cd android && ./gradlew signingReport
//     Repeat for the release keystore before shipping.
//
// Until both platforms are configured the button will appear and the
// account picker will open, but signIn() will throw / return null and no
// idToken will be issued.
// ────────────────────────────────────────────────────────────────────────────

import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/feature_flags.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  /// Triggers the Google account picker.
  ///
  /// Returns the Google-issued idToken on success (to be sent to the
  /// backend at POST /auth/login/google), null if the user cancelled,
  /// or throws if the platform call itself fails.
  Future<String?> signIn() async {
    // Guard against the GoogleSignIn iOS SDK's uncatchable NSException
    // (SIGABRT) when CFBundleURLTypes / GIDClientID are missing. We refuse
    // to invoke the native call at all unless the build flag is on.
    if (!FeatureFlags.googleSigninEnabled) {
      throw Exception('Google sign-in is not configured for this build');
    }
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // user cancelled
      final auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Google sign-out failed: $e');
    }
  }
}
