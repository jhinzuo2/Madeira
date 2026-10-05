#!/usr/bin/env bash
# Configure the native macOS Wine tree that the iOS unix-side scripts consume
# (build/ntdll-unix, build/wineserver, build/win32u-unix read
# wine/build-macos/include/config.h and the widl-generated headers), and the
# ARM64EC tree whose include/ holds dwrite.h / dwrite_3.h.
# Only tools and headers are built, not every PE module.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
JOBS="${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 4)}"
WINE="$ROOT/wine"
MINGW="$ROOT/toolchains/llvm-mingw-20260421-ucrt-macos-universal/bin"
export PATH="$MINGW:$PATH"

[[ -x "$WINE/configure" ]] || { echo "ERROR: wine submodule is missing" >&2; exit 1; }

if [[ ! -f "$WINE/build-macos/Makefile" ]]; then
  echo "Configuring Wine (macOS/aarch64)..."
  mkdir -p "$WINE/build-macos"
  (cd "$WINE/build-macos" && ../configure --enable-archs=aarch64 --disable-tests)
fi

if [[ ! -f "$WINE/build-macos/include/dwrite.h" || ! -x "$WINE/build-macos/tools/winebuild/winebuild" ]]; then
  echo "Building Wine host tools and headers..."
  make -C "$WINE/build-macos" -j"$JOBS" tools/all tools/widl/all tools/winebuild/all include/all
fi

if [[ ! -f "$WINE/build-arm64ec/Makefile" ]]; then
  echo "Configuring Wine (ARM64EC headers)..."
  mkdir -p "$WINE/build-arm64ec"
  (cd "$WINE/build-arm64ec" && ../configure --enable-archs=arm64ec --without-x --disable-tests --enable-winegstreamer)
fi

if [[ ! -f "$WINE/build-arm64ec/include/dwrite.h" || ! -f "$WINE/build-arm64ec/include/dwrite_3.h" ]]; then
  echo "Generating Wine ARM64EC headers..."
  make -C "$WINE/build-arm64ec" -j"$JOBS" include/dwrite.h include/dwrite_3.h
fi

test -f "$WINE/build-macos/include/config.h"
echo "Wine host trees ready"
