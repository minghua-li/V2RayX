#!/usr/bin/env bash
#
# make-release.sh — build, sign, and package V2RayX-mli as a distributable .app.
#
# Builds V2RayX.app (universal: arm64 + x86_64) with a native universal
# v2ray-mli core bundled, code-signs every Mach-O inside the bundle with a
# Developer ID (hardened runtime + secure timestamp), and produces a zip plus
# SHA256SUMS under ./dist.
#
# Usage:
#   SIGN_IDENTITY="Developer ID Application: Name (TEAMID)" ./make-release.sh
#
# Environment:
#   SIGN_IDENTITY  (optional)  codesign identity. If unset, the bundle is left
#                              ad-hoc signed (runs locally; not distributable).
#   OUT_DIR        (optional)  output dir (default: ./dist).
#
# Requires Xcode. GCDWebServer is vendored in-tree (no submodule).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${OUT_DIR:-${REPO_ROOT}/dist}"
BUILD_DIR="${REPO_ROOT}/.build"

cd "${REPO_ROOT}"

if [[ ! -f GCDWebServer/GCDWebServer/Core/GCDWebServer.m ]]; then
  echo "!! vendored GCDWebServer source missing (GCDWebServer/GCDWebServer/Core/GCDWebServer.m)" >&2
  echo "!! it is committed in-tree, not a submodule — your checkout is incomplete" >&2
  exit 1
fi

rm -rf "${BUILD_DIR}" "${OUT_DIR}"
mkdir -p "${BUILD_DIR}" "${OUT_DIR}"

echo ">> building V2RayX.app (Release, universal)"
xcodebuild -project V2RayX.xcodeproj -target V2RayX -configuration Release \
  SYMROOT="${BUILD_DIR}/sym" \
  OBJROOT="${BUILD_DIR}/obj" \
  CONFIGURATION_BUILD_DIR="${BUILD_DIR}/out" \
  CODE_SIGNING_ALLOWED=NO \
  build

APP="${BUILD_DIR}/out/V2RayX.app"
[[ -d "${APP}" ]] || { echo "build did not produce ${APP}"; exit 1; }

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  echo ">> signing nested Mach-O binaries (inner-first) with: ${SIGN_IDENTITY}"
  # Sign every Mach-O inside the bundle before the outer bundle.
  while IFS= read -r f; do
    if file "$f" | grep -q "Mach-O"; then
      codesign --force --timestamp --options runtime \
        --sign "${SIGN_IDENTITY}" "$f"
    fi
  done < <(find "${APP}/Contents" -type f \( -perm +111 -o -name "*.dylib" \))

  echo ">> signing app bundle"
  codesign --force --timestamp --options runtime \
    --sign "${SIGN_IDENTITY}" "${APP}"

  echo ">> verifying signature"
  codesign --verify --deep --strict --verbose=2 "${APP}"
else
  echo ">> SIGN_IDENTITY not set — leaving bundle ad-hoc signed"
fi

echo ">> packaging"
( cd "${BUILD_DIR}/out" && ditto -c -k --sequesterRsrc --keepParent "V2RayX.app" "${OUT_DIR}/V2RayX-mli.zip" )
( cd "${OUT_DIR}" && shasum -a 256 V2RayX-mli.zip > SHA256SUMS && cat SHA256SUMS )

echo ">> done: ${OUT_DIR}/V2RayX-mli.zip"
