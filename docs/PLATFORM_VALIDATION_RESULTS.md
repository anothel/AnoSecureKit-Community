<!-- SPDX-License-Identifier: MPL-2.0 -->
# Platform compatibility validation — 2026-11-17

Baseline: latest origin/main `8a94c591f4d290107c698e6ab7e5598f53fd2b61`,
including merged Phase 6 PR #6. Branch: `codex/revival-platform-validation`.
Publication recommendation remains **NO-GO**. Phase 3 fuzzing and measured coverage
remain **DEFERRED**. Unavailable current security alert data is not cleared;
no security access workaround, alert dismissal, merge, release or tag is authorized.

## Test design

`Cli.WindowsConsole` runs only on native Windows. A detached Python worker
allocates its own genuine Win32 console, passes CONIN$ to the actual CLI, waits
for disabled echo/line/processed modes plus the prompt, and injects Unicode key
records using WriteConsoleInputW. Every case checks exact input-mode restoration,
exit status, secret-free stdout/stderr and absence of the sentinel in the console
screen buffer. Cases cover CR/LF, backspace, Ctrl-C/D/Z cancellation, empty input,
4096-byte acceptance and 4097-byte rejection. Matching password-file fixtures
prove the prompt's actual bytes authenticate, including explicit CP1252 and
CP437 conversions. No password contents are logged. Allocation failure fails
rather than passing a simulation. Worker and CTest outer timeouts bound hangs.

The separate native compatibility workflow builds a shared library and installed
CMake consumer from pinned pre-Phase-4 main
`0cb8bda7b6d96a11bd83228321707f83d62daa4c`. It runs the baseline executable,
freezes its SHA-256, removes the installed runtime and requires execution to fail,
then replaces only that runtime with the candidate installed library. It executes
the unchanged consumer and verifies its hash. No consumer relink or recompilation
occurs after freezing. The old consumer exercises public utility/crypto/file APIs,
packet object lifetimes, and a typed `anosecurekit::error` catch across the library
boundary. Current shared export allowlists run on the replacement build.
JSON evidence and frozen executables are retained as workflow artifacts.

The initially selected post-Phase-4 baseline produced a byte-identical library
on Linux, so the baseline was moved earlier to exercise the visibility correction.
This test is limited to matching architecture/compiler/STL/CRT/OpenSSL runtimes.
It does not establish ABI compatibility for arbitrary downstream layouts or
unsupported private symbols. A missing-runtime negative control checks loader
selection rather than inferring it from a successful launch alone.

## Verification status

Local Linux checks and native CI outcomes will be recorded with immutable commits
below. Merely configuring Windows/macOS jobs does not count as native execution.
No production defect is asserted from static inspection or test scaffolding.

## Remaining limits

Windows ReadConsoleA uses the console input code page. Explicit single-byte code
pages are covered; UTF-8/multibyte editing, surrogate pairs, IME, physical keyboard
layout, ConPTY/remote consoles, console loss and forced termination are not covered.
Backspace removes one byte. Use password files for portable exact binary passwords.
No protection from terminal logging, memory inspection, swap/dumps or guaranteed
erasure is claimed. The harness does not prove recovery from external termination.

Existing filesystem fault-injection and stdout rollback limits still apply.
Platform evidence alone cannot authorize publication: all release blockers must
be separately resolved and a maintainer must authorize reconsidering NO-GO.
