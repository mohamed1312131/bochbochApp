/// Compile-time switch for the backend-free investor demo.
///
/// Production builds keep the default `false`. The Railway demo build uses
/// `--dart-define=DIDO_DEMO_MODE=true` and the dedicated `main_demo.dart`
/// entrypoint.
const bool kDidoDemoMode = bool.fromEnvironment(
  'DIDO_DEMO_MODE',
  defaultValue: false,
);
