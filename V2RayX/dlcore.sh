#!/bin/sh
#
# dlcore.sh — fetch the bundled v2ray-core for V2RayX.
#
# Downloads the native macOS builds of the v2ray-mli fork (a native Apple
# Silicon fork of the archived v2ray-core) and lipo-merges the arm64 and amd64
# slices into a single universal binary. This makes V2RayX run the core
# natively on both Apple Silicon and Intel, avoiding the Rosetta 2
# "not optimized for your Mac" warning that upstream's amd64-only release
# triggers on M-series Macs.
#
# Source release: https://github.com/minghua-li/v2ray-core (tag mli-vX.Y.Z)

set -e

VERSION="4.31.1-mli"
TAG="mli-v4.31.1"
REPO="minghua-li/v2ray-core"

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NORMAL='\033[0m'

cd "$SRCROOT"

# Skip if the bundled core already matches the target version.
if [[ -f ./v2ray-core-bin/v2ray ]]; then
    if ./v2ray-core-bin/v2ray -version 2>/dev/null | head -1 | grep -q "${VERSION}"; then
        echo "${GREEN}v2ray-core ${VERSION} already present — skipping download.${NORMAL}"
        exit 0
    fi
fi

echo "${BOLD}-- Fetching universal v2ray-core ${VERSION} from ${REPO} --${NORMAL}"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

base="https://github.com/${REPO}/releases/download/${TAG}"
fetch () {
    local arch="$1"
    local zip="v2ray-mli-macos-${arch}.zip"
    if ! curl -fsSL -o "${WORK}/${zip}" "${base}/${zip}"; then
        # Fallback: a manually downloaded copy in ~/Downloads
        if [[ -f "${HOME}/Downloads/${zip}" ]]; then
            cp "${HOME}/Downloads/${zip}" "${WORK}/${zip}"
        else
            echo "${RED}download failed: ${zip}"
            echo "Download it from ${base}/${zip} into ~/Downloads and re-run.${NORMAL}"
            exit 1
        fi
    fi
    ( cd "$WORK" && unzip -oq "${zip}" )
}

fetch arm64
fetch amd64

armdir="${WORK}/v2ray-mli-macos-arm64"
amddir="${WORK}/v2ray-mli-macos-amd64"

mkdir -p v2ray-core-bin

echo "${BOLD}-- Merging arm64 + amd64 into universal binaries (lipo) --${NORMAL}"
lipo -create "${armdir}/v2ray" "${amddir}/v2ray" -output ./v2ray-core-bin/v2ray
lipo -create "${armdir}/v2ctl" "${amddir}/v2ctl" -output ./v2ray-core-bin/v2ctl

cp "${armdir}/geoip.dat"   ./v2ray-core-bin/geoip.dat
cp "${armdir}/geosite.dat" ./v2ray-core-bin/geosite.dat

chmod +x ./v2ray-core-bin/v2ray ./v2ray-core-bin/v2ctl

# Re-sign the merged binaries: lipo output is unsigned, and arm64 requires at
# least an ad-hoc signature to execute. The .app's own signing step later
# re-signs the whole bundle with the distribution identity.
codesign --force --sign - ./v2ray-core-bin/v2ray  >/dev/null 2>&1 || true
codesign --force --sign - ./v2ray-core-bin/v2ctl  >/dev/null 2>&1 || true

echo "${GREEN}-- v2ray-core ${VERSION} ready: $(lipo -archs ./v2ray-core-bin/v2ray) --${NORMAL}"
