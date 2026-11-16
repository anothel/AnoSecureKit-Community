<!-- SPDX-License-Identifier: MPL-2.0 -->
# Revival Phase 2 I/O verification — 2026-11-16

Baseline: updated `origin/main`, `21340d31273442cf58d689aed7f5e36bf2b436f2`.
PR #1 was reviewed and already merged before this work; it was not modified.
Branch: `codex/revival-phase2-io`; PR targets `main`. No release or tag changes.
Public headers, SKT1/SKF1/SKP1 v1 bytes, fixtures, KDF parameters, provider
implementation and package identities are unchanged.

## Confirmed defects and fixes

1. Library exclusive output creation closed its descriptor on `fdopen` failure
   but left the already-created private temporary file. Remove that owned path
   on failure on both POSIX and Windows. Linux regression failed before the fix
   for all four path APIs, directly and through CLI path/path commands.
2. Library and CLI hard-link commits ignored temporary-file removal errors and
   reported success with a temporary file remaining. Check removal errors,
   report a generic failure and let existing exception cleanup retry once.
   Keep the committed destination. One-shot unlink faults now report an error
   with final output and no temporary link; persistent faults report an error
   with both links present. Both scenarios are explicitly asserted.
3. CLI credential reads using `istreambuf_iterator` could throw a C++ stream
   diagnostic (`basic_filebuf::underflow ... Input/output error`) instead of
   the generic CLI read error. Catch `ios_base::failure` around the read and
   report `failed to read input file`. The strict error regression reproduced
   this before the change for password-file routes.

Initial unchanged-code regression run (after correcting hook routing) produced
21 failures for fdopen cleanup and silent unlink success. Tightening generic
error assertions subsequently exposed the credential-read defect. Logs:
`/tmp/phase2-red3.log` and the intermediate full-suite log (later replaced by
final verification output). No production changes were made for cases that
already behaved correctly.

## Deterministic coverage and boundaries

`FileIo.FaultInjection` runs 190 fault scenarios plus 13 existing-destination
cases, in isolated subprocesses with fresh directories. It exercises four
library path APIs, four CLI path/path routes, four CLI stdin/path routes, and
keygen as a representative of the shared generic CLI output helper. Phase 1's
all-command output matrix remains registered.

Linux-only `tests/io/faults.cpp` interposes actual stdio/syscalls using a DSO
loaded only by test children. It intercepts libstdc++ file I/O as well as direct
calls. Each case asserts that the selected fault was reached. Hooks cover
exclusive open, input open, fdopen, read, short stdio write, raw write failure,
short raw write, read/write EINTR, fflush, file fsync, consuming fclose/close
errors, hard-link commit, temporary unlink, directory open/fsync/close.
No Linux path uses rename for commit. Windows MoveFileEx failure injection is
not implemented. File fsync failure exercises the CLI stream flush boundary;
the CLI output stream has no separate stdio fflush/fdopen operation.

The test driver calls real public path APIs or real CLI dispatch, verifies
open descriptor counts before/after each operation, and distinguishes library
`backend_failure` from collision `invalid_input`. It does not replace product
implementations. Since stdin can use hidden libc reads, stdin read failure is
injected by setting `cin.badbit` in the driver; it is an observable stream-state
test, not proof of a libc read-EINTR path. Credential reads are excluded from
that stdin injection and tested separately by the CLI path/password routes.

Races create a sentinel destination synchronously immediately before the real
hard-link call. All four library APIs and CLI routes preserve the sentinel and
remove their owned temporary files. There are no sleeps, polling races or
permission/disk-capacity assumptions in these new tests. Every case checks
stdout, generic stderr, final/temp existence and descriptor counts. Successful
partial-write/EINTR retries and post-commit errors additionally validate final
contents (decrypting sealed output), not just file existence.

Hooks are compiled only under `ANOSECUREKIT_BUILD_TESTS` on Linux with CLI enabled,
never linked into product targets or installed. No product environment switch
was added. A shared aggregate test-binaries target ensures nested provider parity
builds the new driver/DSO before running the identical inventory.

## Reproduction and actual results

Environment: Linux x86_64, GCC 14.2.0, OpenSSL 3.5.7, CMake 3.31.6,
Python 3.12.14, GoogleTest v1.14.0, clang-format 22.1.5 installed under `/tmp`.
The preinstalled formatter was 19.1.7; use 22.1.5 for repository checks.
With CMake and Ninja on PATH:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
  -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON \
  -DCLANG_FORMAT_EXE=/tmp/phase2-format/clang_format/data/bin/clang-format
cmake --build build --target check -j4
cmake --build build --target external-backend-parity-check
cmake --build build --target package-check
cmake --build build --target format-check spdx-check legacy-name-check \
  document-alignment-check backend-boundary-check external-backend-hook-check \
  cli-docs-check release-workflow-check release-notes-check examples-check
cmake -S . -B /tmp/phase2-ubsan -G Ninja -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_CXX_FLAGS=-fsanitize=undefined \
  -DCMAKE_EXE_LINKER_FLAGS=-fsanitize=undefined \
  -DCMAKE_SHARED_LINKER_FLAGS=-fsanitize=undefined \
  -DFETCHCONTENT_SOURCE_DIR_GOOGLETEST="$PWD/build/_deps/googletest-src" \
  -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON
UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1 \
  cmake --build /tmp/phase2-ubsan --target check -j4
```

| Check | Actual result |
| --- | --- |
| Release warnings-as-errors build, full CTest | PASS, 128/128 |
| External provider full suite and sorted inventory | PASS, 128/128, identical names |
| Debug UBSan, halt_on_error | PASS, 128/128, no sanitizer diagnostics |
| package-check, archive/install/consumer | PASS |
| clang-format 22.1.5 and listed policy/document checks | PASS |
| Linux/Windows/macOS remote CI | Pending PR run; see PR checks |

Initial harness verification required correcting stdin/credential hook routing,
allowing existing generic CLI open messages, and building all new test binaries
in the nested parity profile. Those failures were not counted as product defects.
Final local logs are `/tmp/phase2-{check,parity,package,policy,ubsan}.log`.

## Tested limitations and untested risks

A final output may exist despite an error after commit, including directory-sync
or temporary-unlink failure. Persistent filesystem refusal may also prevent
cleanup of private temporary files. This cannot be solved by unconditional
retry or deleting the destination. Callers must inspect output state before
retrying. Library path APIs attempt parent-directory sync; CLI output helpers
sync their file but do not sync its parent. Neither promises power-loss survival.

Native Windows/macOS fault hooks, Windows descriptor failure semantics, allocation
failure, real power loss, network filesystems, and adversarial parent-directory
replacement are untested. Linux preload coverage assumes dynamically linked
libc/libstdc++ calls; the explicit reached-hook assertions fail if interception
stops working. Read-EINTR retry evidence is for this runtime. ASan/TSan and fuzz
campaigns were not run in this phase; UBSan is recorded separately.

The existing Linux GCC/Clang and Windows CI matrix is retained; a macOS
AppleClang/OpenSSL 3 check/package job is added. Native fault injection remains
Linux-only even when portable tests run on other platforms. Remote CI status is
recorded in the PR; configuring jobs is not evidence that they passed.

A read-only independent review found harness routing/allowlist and nested parity
build issues; these were corrected. Library error categories now have separate
driver statuses. Minor deferred review note: macOS configuration precedes the
GoogleTest cache restore, which reduces caching effectiveness but not coverage.

Phase 2 PR: https://github.com/anothel/AnoSecureKit-Community/pull/2.
