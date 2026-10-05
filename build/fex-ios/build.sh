#!/bin/bash
# Configure (first time) and build the FEXCore static libraries the app links
# (FEX/build-ios/FEXCore/Source/*.a and External/*). Options mirror the
# development build's CMakeCache.
set -eu
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
B="$R/FEX/build-ios"

# FEX (submodule, willfaust/FEX) calls Win32 VirtualQuery in
# IosLogUnimplementedCASPAL without a _WIN32 guard, so the native Apple build
# does not compile. Apply our fix to the submodule checkout. Idempotent: skipped
# when the patch is already applied.
P="$R/build/fex-ios/patches/arm64-caspal-probe-win32-only.patch"
if git -C "$R/FEX" apply --check "$P" 2>/dev/null; then
    git -C "$R/FEX" apply "$P"
elif ! git -C "$R/FEX" apply --check -R "$P" 2>/dev/null; then
    echo "error: $P neither applies nor is already applied to FEX" >&2
    exit 1
fi

if [ ! -f "$B/CMakeCache.txt" ]; then
    # CMAKE_SYSTEM_PROCESSOR is left empty when cross-compiling with
    # CMAKE_SYSTEM_NAME=iOS on a fresh build dir, and FEX's CMakeLists rejects
    # an empty processor ("Unsupported processor type ."). Set it explicitly.
    # TUNE_CPU=none: the default "native" probes /proc/cpuinfo (Linux only),
    # which does not exist on the macOS runner.
    # FEX_IOS_HOST: switches on the iOS port throughout FEXCore (Core.cpp only
    # declares IosFfsBypassLog/IosCbEntryLog under it, but uses them always).
    # The dev build had it global via CMAKE_*_FLAGS.
    cmake -S "$R/FEX" -B "$B" -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_SYSTEM_PROCESSOR=arm64 \
        -DTUNE_ARCH=generic -DTUNE_CPU=none -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_C_FLAGS=-DFEX_IOS_HOST -DCMAKE_CXX_FLAGS=-DFEX_IOS_HOST -DCMAKE_ASM_FLAGS=-DFEX_IOS_HOST \
        -DCMAKE_OSX_SYSROOT=iphoneos -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=OFF -DBUILD_THUNKS=OFF -DBUILD_FEXCONFIG=OFF -DBUILD_FEX_LINUX_TESTS=OFF \
        -DENABLE_FEX_ALLOCATOR=OFF -DENABLE_ASSERTIONS=OFF -DENABLE_CLANG_THUNKS=ON -DENABLE_CCACHE=ON
fi
# JemallocLibs (AllocatorHooks.cpp) is not a dependency of FEXCore, but the app
# links -lJemallocLibs (app/Madeira.xcodeproj), so build it explicitly.
cmake --build "$B" --target FEXCore FEXCore_Base JemallocLibs
ls "$B/FEXCore/Source/libFEXCore.a" "$B/FEXCore/Source/libFEXCore_Base.a" "$B/FEXCore/Source/libJemallocLibs.a"
