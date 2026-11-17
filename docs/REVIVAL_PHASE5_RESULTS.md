<!-- SPDX-License-Identifier: MPL-2.0 -->
# Phase 5 — CLI password input

Baseline: fetched `origin/main` at `cad3969edaa8c3ced29852ec2af68f217849548a`,
PR #4's merge commit, verified with `git merge-base --is-ancestor` and `git log`.
Branch: `codex/revival-phase5-cli`, based directly on that commit. Phase 3 remains
explicitly deferred. No merge, release, or tag modification is authorized here.

## Implementation and decisions

Explicit `--password-prompt` uses stdin only when it is a terminal/Windows
console, disables echo and native line/processed input, and restores modes via
RAII. Typed Ctrl-C/D/Z cancel, CR/LF completes one entry, backspace removes a byte,
empty input fails, and the prompt is limited to 4096 bytes. No confirmation or
implicit prompting. Conflicting sources and stdin uses fail before reading.

POSIX `--password-fd` consumes a borrowed nonterminal descriptor to EOF without
closing it or changing flags. File/fd passwords retain exact binary bytes. Windows
rejects descriptor input explicitly; password files remain the portable automation
interface. Key descriptors are deferred because existing key files already offer
portable validated input. Existing key-file, key-hex and password-file semantics,
public APIs, v1 wire formats and provider policy remain unchanged.

No new secret-bearing argv/environment option. Unsupported password option names
are no longer echoed, so misplaced secrets cannot enter those diagnostics.
See CLI.md for complete source, ownership and terminal semantics.

## Regression evidence

`python3 tests/cli/check_secret_input.py build/anosecurekit` first failed against
the unchanged CLI: `--password-fd` was unsupported. New tests cover binary raw
passwords, file/fd round trips, inherited pipes, stdin separation, invalid and
empty descriptors, source conflicts, redirected prompts and missing sources.
POSIX isolated pseudo-terminals check no echo, byte editing, cancellation,
empty/oversized input and exact mode restoration. Each child has a 15-second
bound, terminal setup polling has a 5-second bound, and CTest has a 180-second
outer timeout. An open-writer pipe checks conflict rejection before any read.

Independent review found POSIX IXON could consume Ctrl-Q/S. A new matching-file
round-trip test reproduced authentication failure before clearing flow-control
and input translation flags. Added Ctrl-Q/S, CR, Ctrl-Z and exactly-4096-byte cases.
Native Windows console entry is not simulated by the portable redirected-input
checks and remains a limitation even when Windows CI passes.

## Verification

Environment: Linux x86_64, GCC 14.2.0, OpenSSL 3.5.7, Python 3.12.14,
GoogleTest v1.14.0, CMake 4.4.5, Ninja, clang-format 22.1.5. Initial network access
required sandbox escalation for git/dependency fetches. Repository-local tools
also contain older CMake/clang-format versions; 19/23 formatter mismatches were
resolved by selecting the previously verified 22.1.5, without reformatting
unrelated source.

Commands (run from the repository root):

```sh
cmake -S . -B build -DANOSECUREKIT_BUILD_TESTS=ON \
  -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON \
  -DCLANG_FORMAT_EXE=/workspace/phase5-format/clang_format/data/bin/clang-format
cmake --build build --target check format-check
cmake --build build --target cli-docs-check document-alignment-check \
  backend-boundary-check external-backend-hook-check spdx-check legacy-name-check
cmake --build build --target package-check
cmake --build build --target external-backend-parity-check
```

Initial complete CTest run exposed stale expected diagnostics; installed package
checks exposed stale help expectations. These test expectations were updated.
Final verification and native PR CI results are recorded below.

## Remaining limits

External signals/forced termination or terminal loss can prevent restoration.
No portable secure erasure, memory-inspection, swap/dump or terminal-logging
protection is promised. Windows console encoding may differ from POSIX terminal
bytes; use files for portable exact binary passwords. POSIX descriptor aliases
cannot be detected reliably; callers must separate data and password streams,
close pipe writers to provide EOF and manage blocking/lifetime. No native Windows
inherited CRT descriptor interface was added. Existing stdout rollback and
post-commit filesystem limits still apply. No new fuzz campaigns, external audit,
release-readiness or certification claims; Phase 3 remains deferred.

### Local verified results

- Full `check`: **134/134 passed** after the review fix (including security and
  I/O fault matrices); `format-check` with 22.1.5 passed in the same invocation.
- Final package/installed CLI and CMake consumer rerun: **PASS**; ZIP/TGZ source
  and binary packages generated successfully.
- Final external provider parity: **134/134 passed**, identical ordered test
  inventory, including the reviewed secret-input regressions.
- Final checked CLI help, document alignment, backend boundary, external hook,
  SPDX and legacy-name gates: **PASS**.
- Implementation commit: `c5219fe029c72ac0bb33bbcd9ce50cad8f87c74c`.
- PR: https://github.com/anothel/AnoSecureKit-Community/pull/5. Native CI run
  https://github.com/anothel/AnoSecureKit-Community/actions/runs/44019329664
  passed all nine Linux/macOS validation jobs. Both Windows builds compiled and
  passed 131 other tests, but the new explicit descriptor-rejection assertion
  compared native CRLF diagnostics with LF. Updated only that diagnostic
  expectation to use `os.linesep`; raw password bytes are untouched. Native
  rerun results follow; no native Windows interactive-console success is claimed.

### Native rerun

Test-only follow-up: `dd4c9d80044bc18fc45700717ee280d073dd5726`.
[Native run 44020814789](https://github.com/anothel/AnoSecureKit-Community/actions/runs/44020814789)
completed successfully: **all 11 validation jobs passed**. The tag-only release
job was skipped. Verified matrix:

- Linux GCC Release/Debug/static/install-only and Clang Release: PASS.
- Linux GCC/Clang shared tests, ABI export gates, installed/frozen consumers,
  relocated CLI packages and external-provider parity: PASS.
- Linux ASan/UBSan complete suite: PASS.
- macOS AppleClang tests and packages: PASS, including POSIX terminal regressions.
- Native Windows MSVC static/shared: **132/132 CTests each**, package/consumer
  checks, and shared ABI export/consumer gates: PASS. The new redirected-input
  and explicit unsupported-descriptor checks pass with native CRLF diagnostics.

This follow-up changes a diagnostic assertion, not the production implementation.
The subsequent documentation-only commit records these immutable results; it does
not change the runtime or tests validated by this run. Native Windows interactive
console entry, echo/mode restoration and encoding remain unautomated; no such
coverage is inferred from a green Windows build. Other review suggestions not
added to the matrix include PTY conflict-mode snapshots and descriptor-terminal
rejection tests; existing common conflict and no-echo tests plus source review
cover these paths only partially. These are coverage limits, not verified claims.
Phase 3 remains deferred; no merge, release or tag changes were performed.
