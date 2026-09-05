#!/usr/bin/env bash
# Build the Flutter web app on Vercel.
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
SDK_DIR="${CACHE_DIR}/flutter"

if [ -x "${SDK_DIR}/bin/flutter" ]; then
  echo "==> Reusing cached Flutter SDK at ${SDK_DIR}"
else
  echo "==> Fetching Flutter ${FLUTTER_VERSION} (first build only; later builds reuse the cache)"
  rm -rf "${SDK_DIR}"
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
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"

echo "==> Built build/web"
