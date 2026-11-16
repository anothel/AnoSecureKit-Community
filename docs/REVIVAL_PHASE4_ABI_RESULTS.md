<!-- SPDX-License-Identifier: MPL-2.0 -->
# Phase 4 shared-library ABI results — 2026-11-16

Baseline: main `0cb8bda7b6d96a11bd83228321707f83d62daa4c`.
API prerequisite: `b76330faa4e0febf079d5f7d96156c36e0514e5d`, PR #3.
Candidate: `develop/v0.5.0` at `9fe79dc1e0f8b9951e86c2707c70469611ab43e4`.
Branch: `codex/revival-phase4-shared-abi`, initially stacked on the API PR.
PR #3 was merged outside this task at `dd3829fff67973b499c2daf0d6e815dfb6c3dd14`
while the cloud environment was disconnected. PR #4 was then retargeted to main;
the comparison still contains only the ABI integration. Both branches started
from the latest main available at task start. No merge was performed by this task.
Phase 3 remains deferred. No merge, release, version bump or tag change.

## Scope and candidate review

Adapt candidate hidden visibility, public default visibility, class-level error
export, allowlist and installed shared consumer checks. Retain existing public
layouts/signatures and package names. Internal wipe tests compile their own
implementation instead of exporting it for tests. External object providers
receive matching hidden visibility, with no runtime fallback or installed seam.

Improve the candidate gates: validate every MSVC decorated export family and
exact public-function counts instead of checking only five substring tokens;
reject unknown exports. Pass the MSVC linker directory for dumpbin discovery.
Forward toolchain, vcpkg triplet and OpenSSL root into nested package consumers.
Add negative validator tests and a frozen old-source consumer. Historical
status/release assertions stay out. Native Clang CI subsequently demonstrated
that the candidate message-construction rewrites are needed: equivalent append
operations avoid exporting a default-visible libstdc++ operator+ instantiation.
Both exact messages and error categories are retained.

`shared-symbol-check` runs source annotation checks and real ELF/Mach-O/MSVC
export inspection. The reviewed allowlists inventory names/overload counts;
they do not prove parameter layouts or compatibility between arbitrary C++
compiler/STL/runtime versions. Flexible MSVC rules are restricted to generated
`error` constructor/special-member families; all free function counts are exact.

## Actual local evidence

Linux x86_64, GCC 14.2.0, libstdc++, OpenSSL 3.5.7, CMake 3.31.6,
Ninja 1.11.1, Python 3.12.14, GoogleTest 1.14.0, clang-format 22.1.5.

- Before visibility changes, the candidate symbol gate rejected the current
  shared DSO: 117 unique exports versus the expected 52. The extra symbols
  included private OutputFile, provider and crypto/file helpers. Log:
  `/tmp/phase4-abi-red.log`.
- After integration, the actual DSO passes the 52-symbol allowlist. The shared
  full suite passes 133/133 including CLI output security and deterministic
  I/O fault matrices (`/tmp/phase4-abi-shared-check.log`).
- Validator subprocess cases accept a valid inventory and reject missing,
  unexpected and internal exports. These synthetic cases test the gate; they
  do not replace inspecting a real shared library.
- A clean `shared-package-check` build/install passes with current and frozen
  pre-Phase-4 consumers, including typed cross-DSO `anosecurekit::error` catches
  and packet-object lifecycle (`/tmp/phase4-shared-package.log`).
- Frozen consumer source is byte-identical to baseline `tests/consumer/main.cpp`:
  SHA-256 `f153ca1e668d6d2e7c43dff89319a25b720b1fa183c84ad482af919f8f4745e0`.

### Old binary replacement

An archive of baseline main was configured as a shared Release build and
installed under `/tmp/anosecurekit-phase4-baseline/install`. Its original
consumer was built against those headers/library and passed. Then the exact
same binary passed using the current DSO, without relinking:

```sh
LD_LIBRARY_PATH=$PWD/build-shared LD_DEBUG=libs \
  /tmp/anosecurekit-phase4-baseline/consumer/anosecurekit_consumer
```

The loader log confirms `build-shared/libanosecurekit.so` was loaded. Binary
SHA-256 before/after:
`2afcbde2c44e49a5b75aba2139243ebe4862d4742598e5c03265c52b6fe8ed8d`.
This evidence covers that consumer on the same GCC/libstdc++/OpenSSL runtime.
Windows old-binary replacement, other compiler versions, STL ABIs, downstream
layouts not exercised by this consumer and users of private symbols are unproved.

## Verification commands

With the same PATH/formatter as the API results:

```sh
cmake -S . -B build-shared -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON -DANOSECUREKIT_BUILD_TESTS=ON \
  -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON
cmake --build build-shared --target check shared-symbol-check -j 4
cmake --build build --target shared-package-check
cmake --build build --target check format-check package-check external-backend-parity-check
cmake --build build --target backend-boundary-check document-alignment-check \
  cli-docs-check spdx-check legacy-name-check release-workflow-check release-notes-check
```

Static `check` passed 133/133, package checks passed, and ordered external-seam
parity passed 133/133 with identical inventories. A separate shared
external-object-provider build also passed 133/133 and the 52-symbol gate.
Formatting, backend boundary, document alignment, CLI docs, SPDX, legacy-name,
release-workflow and release-notes checks passed.

A full `release-preflight` was attempted. Its documentation assertion fails on
`README version example: project(... VERSION 0.4.1)`. Running the original
preflight script on the untouched baseline archive reproduces the same failure
(`/tmp/phase4-baseline-preflight.log`); release readiness remains blocked. The
API-policy assertion is updated for the additive API wording in this PR, without
weakening format/provider assertions.

Independent review found and prompted fixes for multi-config executable lookup
and a scoped MSVC C4275 warning around the exported exception's STL base. The
multi-config installed consumer gate reproduced `no such file or directory`
after a successful build before the lookup fix; Ninja Multi-Config is now in
the GCC shared CI job. The C4275 concern is based on static MSVC header evidence,
not a locally executed MSVC failure; native CI validates the scoped suppression.
No public class layout changed and warnings remain enabled elsewhere. CI now includes GCC/Clang Linux shared jobs and the
existing Windows shared job runs export and installed-consumer gates. CI accepts
the stacked API branch as a base so this dependent PR runs before either merge.
Remote platform outcomes are recorded below, tied to immutable revisions.

## Remaining risks

No Windows/macOS execution is available locally. Windows export spelling and
cross-DSO exception semantics are checked in native CI (131 tests and 55 unique
DLL exports passed at `6909916`, including both installed consumers). Local old-binary evidence is
not a general ABI guarantee or a release authorization. No fuzz campaign or
coverage claim is added: Phase 3 remains deferred. Provider parity uses the
Community OpenSSL forwarding test implementation, not another production
provider. No secure erasure, certification or external audit is claimed.

## First native CI pass and follow-up

API PR #3 at `b76330f`: Linux GCC Release/Debug/static/install-only, Clang Release,
ASan/UBSan, macOS and Windows static/shared tests and packages all passed;
[run 43867072525](https://github.com/anothel/AnoSecureKit-Community/actions/runs/43867072525)
completed successfully. No release job ran.

ABI PR #4 at `6909916`, run 43868810732: native Windows shared tests, packages,
complete decorated export gate and both installed consumers passed. Windows
static, macOS, Linux static/Debug/install-only and sanitizers also passed.
The new GCC shared job passed 133 tests and its symbol inventory, then reproduced
an installed CLI loader failure. The Clang shared job rejected an unexpected
libstdc++ `operator+` symbol. Neither failure was waived.

Follow-up regression: copy the installed shared package to a new prefix, clear
loader-path environment variables and invoke its CLI. It failed before the fix
(`/tmp/phase4-relocated-cli-red.log`). Set the shared UNIX CLI install rpath
relative to its own executable (`$ORIGIN` on ELF, `@loader_path` on macOS), using
the configured bin-to-library relative path. Retain system OpenSSL dependencies.
Apply the two candidate append-based message constructions to remove the Clang
STL export without widening the allowlist. Final reruns are recorded separately.

## Final implementation verification

Implementation commit: `e5e3d3911aa143db98c2c7e1ee2fdc30654ace02`.
[Native CI run 43973468472](https://github.com/anothel/AnoSecureKit-Community/actions/runs/43973468472).
The connected GitHub service published exactly the locally verified tree
`b943dc833f476f9a4e0127d83d6d78dd112b2f2b` after terminal Git credentials
became unavailable; local and remote commit/tree identities were reconciled.

- GCC Multi-Config shared ABI, installed packages/relocation, consumers and
  provider parity: PASS.
- Clang shared ABI, installed packages/relocation, consumers and parity: PASS;
  the original unexpected STL export is gone without an allowlist change.
- Linux GCC Release/Debug/static/install-only and Clang Release: PASS.
- ASan/UBSan full suite and macOS package job: PASS.
- Native Windows static/shared rerun: PASS, including 131 shared CTests,
  55 unique DLL exports, and current/frozen installed consumers.
- All 11 validation jobs passed; the tag-only release job was skipped.

After the follow-up, local shared `check` passed 133/133 and full shared
`package-check` passed, including copied-prefix invocation with both loader-path
environment variables cleared. The installed ELF CLI has `$ORIGIN/../lib` as
its default RUNPATH. Existing user-supplied install rpaths are retained.

The final documentation commit records this immutable implementation revision;
it does not change runtime code. The baseline release-preflight documentation
blocker, Windows old-binary replacement gap, compiler/runtime ABI limits and
Phase 3 fuzz/coverage deferral remain as stated above.
