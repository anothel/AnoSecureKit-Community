<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Shared Library ABI

Status: Phase 4 integration candidate, unreleased; no version bump

## Decision

Shared builds hide symbols by default and export only the reviewed public C++ ABI.
`ANOSECUREKIT_API` is the only supported source annotation for that ABI. On Windows it maps to the
existing `__declspec(dllexport/dllimport)` contract; on GCC and Clang shared
builds it maps to default symbol visibility.

Internal namespaces, provider functions, file-I/O helpers, and secure wipe are
not public ABI even when they are linked into the same library. In particular,
these names must never appear in the dynamic export surface:

```text
anosecurekit::detail
anosecurekit::internal
anosecurekit::internal_aead
anosecurekit::internal::secure_wipe
```

`anosecurekit::error` is exported at class scope so its exception RTTI remains
usable across a shared-library boundary. The public function and class inventory
is recorded in `cmake/shared_symbol_allowlist.txt`. A narrow MSVC C4275
suppression surrounds this declaration because the standard exception base lacks
a DLL class annotation; it does not change class layout or suppress other warnings.

## Gates

- `shared-symbol-annotation-check` verifies the source visibility policy and
  rejects public export annotations in internal headers.
- `shared-symbol-check` inspects an actual shared library. ELF and Mach-O builds
  must match the reviewed demangled allowlist exactly. Windows uses DLL export
  inspection against `shared_symbol_allowlist_msvc.txt` for every export and
  exact counts for public function families, plus the annotation contract.
  Compiler-generated `error` special members have explicit flexible rules.
- `shared-package-check` creates a clean shared build, installs it, runs the
  symbol gate, builds an external consumer against the installed package, and
  verifies cross-DSO exception handling and the public API. A frozen pre-Phase-4
  consumer source (`tests/abi/v041_consumer.cpp`, from main `0cb8bda`) also builds
  against the installed current headers and library. This proves source
  compatibility on that toolchain, not cross-version binary compatibility.
- `release-preflight` includes the annotation and shared-package gates.

## Compatibility

The visibility correction does not change public function signatures, CMake
package identity, CLI behavior, provider selection, or v1 format meanings. Code
that linked directly to uninstalled `detail` or internal symbols was outside the
supported API and is intentionally rejected by this policy.

## Binary compatibility limits

No public class layout, public signature, package/target name or SONAME is changed.
An unchanged baseline consumer binary is tested locally with the replacement DSO;
see REVIVAL_PHASE4_ABI_RESULTS.md for exact commits and commands. This evidence is
limited to the same GCC/libstdc++/OpenSSL runtime. Windows uses native CI gates for
current/frozen-source consumers and DLL exports; no Windows old-binary replacement
or cross-compiler C++ ABI promise is made. The allowlists inventory symbol families,
not every parameter encoding, object layout, calling convention or STL ABI.
Existing consumers that intentionally used internal symbols must be rebuilt using
installed public headers; those internal exports were never a supported contract.

## Platform validation follow-up

The focused native frozen-binary workflow and exact pre-Phase-4 baseline are
recorded in [PLATFORM_VALIDATION_RESULTS.md](PLATFORM_VALIDATION_RESULTS.md).
It builds against the earlier installed package once, checks baseline execution
and a missing-runtime negative control, replaces only the runtime, and verifies
the executable hash after execution. Native results are recorded there separately
from Linux evidence and frozen-source rebuilds. This adds no cross-toolchain ABI
promise and does not change the NO-GO publication recommendation.
