# DIDO static investor demo

This target is a fully client-side Flutter Web application. It uses the
production UI with seeded, stateful in-memory repositories. It does not start
or call the backend.

## Run locally

```bash
flutter run -d chrome \
  --target lib/main_demo.dart \
  --dart-define=DIDO_DEMO_MODE=true
```

## Build locally

```bash
flutter build web \
  --release \
  --no-wasm-dry-run \
  --target lib/main_demo.dart \
  --dart-define=DIDO_DEMO_MODE=true
```

The static output is written to `build/web`.

## Deploy on Railway

1. Create a new Railway service from the Flutter GitHub repository.
2. If this Flutter project is inside a monorepo, set the service root directory
   to `/bochboch`.
3. Railway detects `railway.toml` and builds the included multi-stage
   `Dockerfile`.
4. Generate a public domain in **Settings → Networking**.
5. Open the generated HTTPS URL on the CEO's phone.

The Caddy configuration serves the Flutter assets, reads Railway's `PORT`, and
falls back to `index.html` for client-side routes. A strict content-security
policy only permits connections to the demo's own origin, so production API
and analytics hosts cannot be contacted by this build. CanvasKit is loaded
from the bundled `build/web/canvaskit` directory instead of Google's CDN in
release builds. Local `flutter run` debug sessions use Flutter's normal SDK
CDN because the development server does not expose that bundled directory.

## Demo behavior

- Data lives only in the current browser tab.
- Refreshing the page restores the initial scenario.
- **Settings → Mode démo → Réinitialiser les données** also restores it.
- Product, order, customer, stock, boutique, and goal changes are simulated
  locally and never leave the device.
