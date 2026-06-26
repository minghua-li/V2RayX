# Vendored dependency: GCDWebServer

This directory was previously a git **submodule** of
[`swisspol/GCDWebServer`](https://github.com/swisspol/GCDWebServer). It is now
**vendored** (committed directly into the V2RayX-mli repo).

| | |
|---|---|
| Upstream | https://github.com/swisspol/GCDWebServer |
| Version | 3.5.2 |
| Pinned commit | `7e4dd53c9837019be15688c6f46525d241494920` |
| License | BSD (see `LICENSE` in this directory) |
| Vendored on | 2026-06-25 |

## Why vendored

Upstream was **archived (read-only) on 2023-01-11** — it will never receive
updates, and an archived GitHub repo can still be deleted by its owner. Keeping
it as a submodule meant the V2RayX build depended on an external, frozen,
deletable repo. Vendoring the source makes the build self-contained and
reproducible regardless of upstream's fate.

There is no functional reason tied to this code being "old": V2RayX compiles it
from source (so it is natively arm64/universal), uses only a minimal HTTP-server
surface (serves `/proxy.pac` and `/config.json` on localhost:8070, no TLS), and
the 2019 source uses no removed macOS APIs — it builds and runs cleanly on
current macOS. Vendoring is purely about removing the external-repo dependency.

## How it is built

The V2RayX Xcode target compiles the source files under
`GCDWebServer/Core`, `GCDWebServer/Requests`, and `GCDWebServer/Responses`
directly (see `V2RayX.xcodeproj`). The sibling `GCDWebDAVServer/`,
`GCDWebUploader/`, `Tests/`, and `GCDWebServer.xcodeproj` are **not** compiled by
V2RayX; they are kept only to preserve the upstream tree intact.

## Updating

Upstream is archived, so there is normally nothing to update. If the minimal
HTTP-server use ever needs replacing, the cleanest path is not re-vendoring but
rewriting V2RayX's two-handler usage on `Network.framework` (`NWListener`) and
dropping this directory entirely.
