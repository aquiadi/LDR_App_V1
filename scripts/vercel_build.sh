#!/usr/bin/env bash
# Build the site on Vercel: the landing page plus the Flutter web app.
#
# Vercel has no Flutter runtime, so the SDK is fetched here. It is placed in
# .vercel/cache, which Vercel restores between builds -- without that, every
# deploy re-downloads ~1.5 GB.
#
# The important part: this app reads its Supabase credentials through
# String.fromEnvironment, which Dart resolves at COMPILE time. Setting
# SUPABASE_URL in the Vercel dashboard does nothing on its own; the values have
# to be forwarded into the compiler as --dart-define, which is what happens at
# the bottom of this script.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.9}"
CACHE_DIR="${PWD}/.vercel/cache"
# Versioned path, so changing FLUTTER_VERSION actually fetches that version
# instead of silently reusing whichever SDK happens to be cached.
SDK_DIR="${CACHE_DIR}/flutter-${FLUTTER_VERSION}"

if [ -x "${SDK_DIR}/bin/flutter" ]; then
  echo "==> Reusing cached Flutter SDK at ${SDK_DIR}"
else
  echo "==> Fetching Flutter ${FLUTTER_VERSION} (first build only; later builds reuse the cache)"
  # Drop SDKs for other versions so the build cache does not keep growing.
  rm -rf "${CACHE_DIR}"/flutter "${CACHE_DIR}"/flutter-*
  mkdir -p "${CACHE_DIR}"
  git clone --depth 1 --branch "${FLUTTER_VERSION}" \
    https://github.com/flutter/flutter.git "${SDK_DIR}"
fi

export PATH="${SDK_DIR}/bin:${PATH}"
git config --global --add safe.directory "${SDK_DIR}" || true

flutter --version

if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo ""
  echo "  !! SUPABASE_URL / SUPABASE_ANON_KEY are not set for this deployment."
  echo "  !! The build will succeed, but the app will boot to its"
  echo "  !! 'Sync Setting Required' screen instead of the login page."
  echo "  !! Set both in Vercel -> Settings -> Environment Variables, then redeploy."
  echo ""
fi

flutter pub get

# --no-web-resources-cdn bundles CanvasKit with the app rather than pulling it
# from gstatic.com at runtime, matching how the fonts are handled: no
# third-party fetch is needed for the app to render.
flutter build web --release \
  --no-web-resources-cdn \
  --base-href /app/ \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"

# The site is the static landing page at / with the Flutter app under /app/.
# The landing page is plain HTML so it loads instantly; the app is ~40 MB of
# CanvasKit and only downloads once someone actually opens it.
rm -rf build/site
mkdir -p build/site
cp -R web_landing/. build/site/
cp -R build/web build/site/app

echo "==> Built build/site (landing at /, app at /app/)"
