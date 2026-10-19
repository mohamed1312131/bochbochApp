{{flutter_js}}
{{flutter_build_config}}

// Flutter's development server does not expose the bundled CanvasKit folder,
// so debug builds keep Flutter's normal SDK CDN. Release builds (Railway)
// load the CanvasKit files emitted into build/web and are locked to same-origin
// connections by Caddy's CSP header.
const isDebugBuild = _flutter.buildConfig.builds.some(
  (build) => build.compileTarget === "dartdevc",
);

_flutter.loader.load({
  config: isDebugBuild ? {} : { canvasKitBaseUrl: "canvaskit/" },
});
