// wine_stubs.c - Provide missing symbols for Wine on iOS

#include <CoreFoundation/CoreFoundation.h>

// Wine build version string (normally generated at compile time)
const char wine_build[] = "wine-10.0-ios";

// IOPowerSources stubs - not available on iOS
CFTypeRef IOPSCopyPowerSourcesInfo(void) { return NULL; }
CFArrayRef IOPSCopyPowerSourcesList(CFTypeRef blob) { (void)blob; return NULL; }
CFDictionaryRef IOPSGetPowerSourceDescription(CFTypeRef blob, CFTypeRef ps) {
    (void)blob; (void)ps; return NULL;
}

// ---------------------------------------------------------------------------
// FEXCore host-side stubs (iOS app link).
//
// libFEXCore.a is built with -DFEX_IOS_HOST, which makes FEXCore reference
// symbols that are normally supplied by the ARM64EC/WOW64 PE module
// (FEX/Source/Windows/ARM64EC/IosJitAlias.cpp) or by the rpmalloc fork
// (External/rpmalloc, not built on Apple: ENABLE_FEX_ALLOCATOR is forced off).
// The native app process has no alias table, no Mono bridge and no rpmalloc,
// so every stub reports "miss / inactive" and FEXCore takes its fallback path.
// Weak, so a real definition (e.g. rpmalloc linked later) wins without a
// duplicate-symbol error.
// ---------------------------------------------------------------------------
#include <stdint.h>
#include <stddef.h>

#define MADEIRA_WEAK __attribute__((weak))

// VA band the FEX arena is carved from. 0 = unset -> AllocatorHooks falls back.
MADEIRA_WEAK uintptr_t ios_fex_band_base = 0;
MADEIRA_WEAK uintptr_t ios_fex_band_end = 0;

// rpmalloc CAS-failure snapshot sampler: nothing to drain.
MADEIRA_WEAK int rpm_cas_snapshot_take(void *out) { (void)out; return 0; }

// JIT alias table: no aliases here, so resolution misses (0) and sub-floor
// addresses map to themselves.
MADEIRA_WEAK uint64_t IosMonoResolveRW(uint64_t guest_addr, uint64_t size) {
    (void)guest_addr; (void)size; return 0;
}
MADEIRA_WEAK uint64_t IosSubfloorToReal(uint64_t addr) { return addr; }

// Mono bridge: never armed, nothing pending.
MADEIRA_WEAK int ios_fex_mono_bridge_armed(void) { return 0; }
MADEIRA_WEAK int ios_fex_mono_take_pending(uint64_t *block_begin, uint64_t *host_pc,
                                           uint64_t *fault_addr) {
    (void)block_begin; (void)host_pc; (void)fault_addr; return 0;
}
MADEIRA_WEAK void ios_fex_mono_count_activated(void) {}
MADEIRA_WEAK void ios_fex_mono_count_helper(int miss) { (void)miss; }
MADEIRA_WEAK uint64_t ios_fex_mono_captured_count(void) { return 0; }

// terminfo: libdxmt_combined.a contains LLVM's Process.cpp, which calls
// setupterm()/tigetnum() to detect colour support. The iOS SDK has no usable
// curses to link, so report "no terminal": setupterm fails -> no colours.
MADEIRA_WEAK int setupterm(char *term, int fd, int *errret) {
    (void)term; (void)fd; if (errret) *errret = 0; return -1;
}
MADEIRA_WEAK void *set_curterm(void *term) { (void)term; return NULL; }
MADEIRA_WEAK int del_curterm(void *term) { (void)term; return -1; }
MADEIRA_WEAK int tigetnum(char *cap) { (void)cap; return -2; }
