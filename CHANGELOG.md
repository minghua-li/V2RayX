# Changelog

All notable changes to this fork (**V2RayX-mli**) are documented here.

This fork of the archived [`Cenmrev/V2RayX`](https://github.com/Cenmrev/V2RayX)
adds native **Apple Silicon (M-series)** support. It bundles the
[`v2ray-mli`](https://github.com/minghua-li/v2ray-core) core — a native arm64
fork of the archived v2ray-core — instead of upstream's amd64-only binary.
Versions use an `-mli` suffix and tags use the `mli-vX.Y.Z` prefix to stay
distinct from upstream.

## [1.5.3-mli] — 2026-06-25

### Changed

- Raised `MACOSX_DEPLOYMENT_TARGET` from 10.12 to **10.13**, the minimum
  supported by current Xcode (Xcode 26 supports 10.13+). Silences the build
  warning and keeps the project building cleanly on modern toolchains. No
  functional change; the app remains a universal (arm64 + x86_64) build.

## [1.5.2-mli] — 2026-06-25

First fork release. The app and its bundled core both run natively on Apple
Silicon and Intel.

### Why this fork exists

Upstream V2RayX downloads and bundles the v2ray-core macOS release, which was
only ever built for `darwin/amd64`. On Apple Silicon that core runs under
Rosetta 2, producing the macOS *"not optimized for your Mac / future versions
of macOS will not support it"* warning. This fork bundles a native core and
builds the app as a universal binary.

### Changed

- **`V2RayX/dlcore.sh`** now downloads the
  [`v2ray-mli`](https://github.com/minghua-li/v2ray-core) release
  (`mli-v4.31.1`) instead of upstream `v2ray/v2ray-core` `v4.18.0`, fetching
  both the `arm64` and `amd64` builds and `lipo`-merging them into a single
  **universal** `v2ray` / `v2ctl`. The bundled core therefore runs natively on
  both architectures. The merged binaries are ad-hoc re-signed (required for
  arm64 execution); the app bundle is later signed with a Developer ID.
- Version bumped to `1.5.2-mli`.

### Notes

- The app shell builds as a universal binary under modern Xcode
  (`ARCHS = $(ARCHS_STANDARD)`, deployment target macOS 10.12+).
- The bundled core has **no QUIC transport** (removed in the `v2ray-mli` fork
  for Go-toolchain compatibility — see that project's CHANGELOG). All other
  transports and proxy protocols are unchanged.
- Release `.app` is Developer ID signed but **not notarized**.

### Build

Requires the `GCDWebServer` git submodule:

```bash
git submodule update --init --recursive
xcodebuild -project V2RayX.xcodeproj -target V2RayX -configuration Release
```

[1.5.3-mli]: https://github.com/minghua-li/V2RayX/releases/tag/mli-v1.5.3
[1.5.2-mli]: https://github.com/minghua-li/V2RayX/releases/tag/mli-v1.5.2
