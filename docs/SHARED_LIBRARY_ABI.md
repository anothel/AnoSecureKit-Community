<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Shared Library ABI

Status: v0.5.0 feature policy

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
is recorded in `cmake/shared_symbol_allowlist.txt`.

## Gates

- `shared-symbol-annotation-check` verifies the source visibility policy and
  rejects public export annotations in internal headers.
- `shared-symbol-check` inspects an actual shared library. ELF and Mach-O builds
  must match the reviewed demangled allowlist exactly. Windows uses DLL export
  inspection plus the class/function annotation contract.
- `shared-package-check` creates a clean shared build, installs it, runs the
  symbol gate, builds an external consumer against the installed package, and
  verifies cross-DSO exception handling and the public API.
- `release-preflight` includes the annotation and shared-package gates.

## Compatibility

The visibility correction does not change public function signatures, CMake
package identity, CLI behavior, provider selection, or v1 format meanings. Code
that linked directly to uninstalled `detail` or internal symbols was outside the
supported API and is intentionally rejected by this policy.
