<!-- SPDX-License-Identifier: MPL-2.0 -->
# Revival Phase 1 verification — 2026-11-15

Baseline: `298bcbd125cafae26cf54a6ec81c98b7f729b477` (matches remote main).
Branch: `codex/revival-20261115`. Source remains unpublished version 0.4.1.
This is internal maintenance verification, not an external security audit.

## Changes and findings

Existing CLI permission hardening (`df19367`) and fuzz fixture normalization
(`c3872c1`) were retained. No production-code defect was reproduced in this
phase's exercised paths. Added `Cli.OutputSecurity` (Python standard library,
POSIX only) and two GoogleTest fuzz-adapter regressions. No public header, crypto
implementation, format, fixture, package identity or provider policy changed.

The CLI matrix exercises 13 output routes: keygen, wrap/unwrap, encrypt/decrypt,
raw-key/password seal/open, and stdin variants of all four file commands.
It checks all routes under umask 000 and 022 for exact 0600 final permissions,
no stdout, repeat-output refusal, preservation of existing bytes and legacy
`.anosecurekit.tmp` sentinels. Every route also refuses existing directories,
regular-target symlinks and dangling symlinks without replacing them or their targets.

Raw-key/password stdin operations hold input open while the test observes a 0600
random temporary file, then creates the destination before allowing completion.
Exclusive hard-link commit refuses overwrite, preserves the racing writer's bytes
and removes the owned temporary file. Static inspection confirms O_CREAT|O_EXCL
and mode 0600 in both CLI and library creation paths; exclusive temp-name collision
retry/exhaustion is not fault-injected here.

Final-tag corruption after a full 1 MiB authenticated chunk leaves no path output
or random temporary file for raw-key/password opens, with both path and stdin
inputs. Wrong-key packet decrypt/unwrap produces generic authentication errors,
no stdout and no output. Existing tests cover wrong AAD/password and malformed
fixtures. stdout file opens deliberately retain the first authenticated chunk on
late tag failure: callers must check exit status and stage output themselves.

Fuzz tests exercise every accepted ASCII whitespace character before fixture
hex decoding and preserve non-fixture inputs as raw bytes. Compiling these tests
against the pre-c3872c1 adapter in a temporary directory reproduces the expected
whitespace-test failure (`hex input must contain an even number of characters`);
the current adapter passes both. Production code was never reverted.

## Reproduction and results

Environment: Linux x86_64, GCC 14.2.0, OpenSSL 3.5.7, CMake 4.4.5,
GoogleTest v1.14.0, Python 3.13, clang-format 22.1.5. Missing build/format tools
were installed into /tmp; no repository dependency files were changed.

Configure (use the corresponding CMake/formatter paths in your environment):

```sh
cmake -S . -B /tmp/anosecurekit-revival-build -DCMAKE_BUILD_TYPE=Release \
  -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON -DCLANG_FORMAT_EXE=/path/to/clang-format-22
cmake --build /tmp/anosecurekit-revival-build --target check -j4
cmake --build /tmp/anosecurekit-revival-build --target format-check
cmake --build /tmp/anosecurekit-revival-build --target package-check
cmake --build /tmp/anosecurekit-revival-build --target external-backend-parity-check
```

| Check | Actual result |
| --- | --- |
| Release warnings-as-errors build and CTest | PASS, 127/127 |
| POSIX CLI matrix standalone | PASS, 4 methods with route/profile subtests |
| External backend parity | PASS, 127/127 and identical ordered inventory |
| package-check | PASS, initial and final runs |
| format-check, clang-format 22.1.5 | PASS |
| SPDX, legacy identifiers, document alignment, backend boundary | PASS |
| CLI documentation, release workflow, release notes extraction, examples | PASS |
| Missing Python configure guard | PASS: reproduced skip, then explicit configure failure |
| Historical fuzz-adapter mutation | Expected failure reproduced; current tests PASS |

The parity adapter is a build-tree OpenSSL-backed test provider, not evidence
for Enterprise or a different cryptographic module. Package checks create local
archives and validate installed CLI/consumers; they do not publish a release.
Full command logs are retained under `/tmp/revival-*.log` for this workspace.

Initial CTest discovery failed with `text file is busy` while overlapping package
builds relinked its executable. A later full run passed; do not overlap builds
that write the same targets. Formatting initially failed with clang-format 23.1.5
(two untouched consumer/provider files) and 18.1.8 (constructor formatting in
untouched files); 22.1.5 passes the whole tree without formatting churn.

## Remaining risks and unavailable checks

- Windows/MSVC and macOS were not run locally. POSIX-only tests are deliberately
  not registered there; existing portable CLI/file tests remain available.
- Full libFuzzer campaigns, sanitizer runs and measured coverage were not run;
  Clang/libFuzzer are absent. The complete-SKP1-header fuzz skip remains a Phase 3 gap.
- The destination-created race covers the CLI stdin commit helper; the separate
  library path/path commit helper race still needs Phase 2 coverage.
- No deterministic disk-full, fdopen/allocation, flush/close, commit/unlink or
  directory-sync fault injection yet. Phase 2 owns these rare cleanup paths.
- A restrictive umask may remove owner bits; 0600 is a maximum permission grant,
  not a promise to override caller policy. Parent-directory security still matters.
- CLI commits use hard links and need filesystem support. CLI fsyncs its file but
  does not sync the parent directory; library path APIs also attempt directory sync.
  Post-commit directory-sync failure may report failure with output already present.
- Final external security review, support/release decisions and parked v0.5.0
  API/ABI integration remain follow-up phases; no merge or publication is authorized.
- Branch push succeeded with network access enabled. GitHub CLI auth diagnostics
  report an invalid GH_TOKEN; the actual `gh pr create` request failed with
  `Post "https://api.github.com/graphql": Forbidden`. PR creation is blocked by
  CLI API access; the connected GitHub tool subsequently succeeded and opened
  https://github.com/anothel/AnoSecureKit-Community/pull/1. The pushed branch is at
  https://github.com/anothel/AnoSecureKit-Community/tree/codex/revival-20261115.

## Review disposition

A separate read-only reviewer ran the Python matrix and fuzz regressions and
confirmed both provider inventories include them. Its important finding (silent
skip without Python) was reproduced with CMAKE_DISABLE_FIND_PACKAGE_Python3=TRUE
and fixed by requiring Python 3.7+ when POSIX CLI tests are enabled. The same
configure now fails as expected; production builds with tests disabled add no
Python requirement. The reviewer's path/path race coverage gap is deferred to
Phase 2; its Python minimum-version concern is fixed. No production-code change
was needed. Final release-preflight was not run; it remains Phase 6 work.
