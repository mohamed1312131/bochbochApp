FROM ghcr.io/cirruslabs/flutter:3.41.2 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web \
    --release \
    --no-wasm-dry-run \
    --target lib/main_demo.dart \
    --dart-define=DIDO_DEMO_MODE=true

FROM caddy:2-alpine

COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/build/web /srv

EXPOSE 8080
