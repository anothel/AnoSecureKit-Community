<!-- SPDX-License-Identifier: MPL-2.0 -->
# Maintenance revival implementation plan

> Execute inline using superpowers:executing-plans, one reviewable phase per PR.

**Goal:** Resume Community maintenance under the user's 2026-11-15 instruction.
**Architecture:** Verify existing hardening first; add tests around observable CLI
contracts. Keep API/ABI integration separate from maintenance and release decisions.
**Tech stack:** C++20, CMake, OpenSSL 3, GoogleTest, Python 3 (POSIX CLI matrix).
**Spec:** User maintenance request; docs/SECURITY_MODEL.md and docs/FORMAT.md.

## Global constraints

Baseline: main at 298bcbd125cafae26cf54a6ec81c98b7f729b477; working branch
codex/revival-20261115. The local checkout initially named this commit `work` and
had no local main ref. Published v0.4.0 remains distinct from unpublished source
0.4.1. Historical frozen documents are superseded only for maintenance scope by
this explicit instruction; this does not establish a support SLA or authorize a
release. Preserve API compatibility, v1 formats, OpenSSL provider policy and
Community/Enterprise separation. No merge, publication, tag edits or alert dismissal.

## Review focus

- Permissive umask: keys/plaintext/packets still private at creation and commit.
- Existing files, directories and symlinks: no overwrite or removal.
- Destination created during operation: exclusive commit must preserve it.
- Late authentication failure: no committed file or owned temporary leftovers.
- stdout: authenticated earlier file chunks may be visible after later failure.

## Phase 1 — verify maintenance security (verified locally; PR #1 merged)

Files: AGENTS.md, tests/cli/check_output_security.py, tests/fuzz_fixture_test.cpp, CMakeLists.txt,
docs/REVIVAL_PLAN.md, docs/REVIVAL_PHASE1_RESULTS.md.
Existing fixes: df19367 uses exclusive randomized CLI temporary files, 0600,
fsync/close and hard-link no-overwrite commit. File APIs already use private output
and authenticate all chunks before commit. Existing tests cover generic outputs,
wrong AAD/password, fixture rejection and file cleanup. Fuzz harnesses retain
unexpected exceptions; password-file fuzzing skips complete SKP1 headers to bound
scrypt cost, leaving an explicit Phase 3 coverage gap.

- [x] Read status, queue, security model, format, CLI/file/fuzz tests and provider policy.
- [x] Create dedicated working branch and repository rules.
- [x] Add matrix covering every path-producing CLI command under umask 000/022,
      stdin variants, existing regular/symlink/dangling/directory destinations,
      late tamper cleanup and a destination-created-during-operation race.
- [x] Run regressions against unchanged production code; fix only reproduced defects.
- [x] Run CMake suite, formatting, packages, provider parity and policy checks;
      document actual results and unavailable platforms/tools.
- [x] Commit and push focused Phase 1 branch.
- [x] Open focused PR: https://github.com/anothel/AnoSecureKit-Community/pull/1
      (connected GitHub tool succeeded after CLI API access was forbidden).

Acceptance: matrix plus existing suite pass, no API/format drift, reproducible
results with explicit limitations. Tests verifying existing fixes may pass first.
Risks: filesystem assumptions, Windows untested locally, fault paths not injected.

## Phase 2 — file I/O fault injection (separate PR)

Files: src/file_io.cpp, src/cli/commands.cpp, tests/file_test.cpp and new test-only
fault harness under tests/. Preserve public interfaces; use test link wrappers or
an internal seam, never public production switches.
- [x] Write failing cases for open/fdopen, read, short write/EINTR, flush/fsync,
      close, link/rename, temp unlink and parent directory sync failures.
- [x] Assert generic error categories, descriptor closure, owned-temp cleanup and
      preservation of pre-existing files; post-commit sync failure may leave output.
- [x] Reproduce any defect, minimally fix it, run suite/parity and commit.
Acceptance: deterministic failure matrix for CLI and path APIs; no timing-only tests.
Risk: fdopen/allocation failures and cleanup failure need explicit ownership checks;
      CLI and library durability guarantees differ.

## Phase 3 — targeted fuzzing and coverage (deferred; separate PR)

Files: tests/fuzz/file_fuzz.cpp, fuzz_utils.hpp, CMakeLists.txt, .github/workflows/fuzz.yml.
- [ ] Instrument library and harnesses with ASan/UBSan and coverage, use copied corpora.
- [ ] Add bounded valid SKP1 cases exercising KDF/authentication without unbounded cost.
- [ ] Target chunk boundaries, terminal records, packet state transitions and encodings;
      minimize failures into regression fixtures. Report duration, seeds and coverage.
Acceptance: all five harnesses smoke-pass, bounded campaigns and measured coverage
      gaps documented. No claim that crash-free fuzzing proves security.

## Phase 4 — integrate parked v0.5.0 safely (separate API/ABI PRs)

Candidate: develop/v0.5.0 at 9fe79dc1e0f8b9951e86c2707c70469611ab43e4.
Files: include/anosecurekit/file.hpp, implementation/tests, shared-library export rules.
- [x] Obtain exact branch and compare with latest main (including Phases 1–2); do not merge blindly.
- [x] Review verification APIs, error behavior and discarded plaintext ownership.
- [x] Test old consumers, header compatibility, shared exports and ABI allowlist on
      Linux/Windows; rerun format fixtures, installed packages and ordered parity.
Acceptance: additive APIs only, explicit ABI decision and no lost maintenance fixes.
Candidate retrieved and reviewed; API PR #3 was merged outside this task.
ABI PR #4 merged as cad3969edaa8c3ced29852ec2af68f217849548a.
Implementation e5e3d39 passed all 11 native CI validation jobs; no release ran.
Results: [REVIVAL_PHASE4_API_RESULTS.md](REVIVAL_PHASE4_API_RESULTS.md) and
[REVIVAL_PHASE4_ABI_RESULTS.md](REVIVAL_PHASE4_ABI_RESULTS.md).
Risk: compiler/runtime-specific ABI evidence; Windows old-binary replacement remains untested.

## Phase 5 — CLI secret handling (separate PR)

Files: src/cli/commands.cpp, docs/CLI.md, tests/cli/.
- [x] Specify optional file/descriptor/prompt input with precedence and stdin conflicts.
- [x] Test exact password bytes, empty inputs, no echo/log disclosure and error paths.
- [x] Preserve existing options; document argv/process-list exposure and memory limits.
Acceptance: backward compatible inputs and documented ownership; no erasure promises.

## Phase 6 — final security and release readiness (separate review PR)

- [ ] Review full delta against threat model, triage open alerts without dismissing them.
- [ ] Run supported compiler/platform/provider matrix, package consumers, ABI checks,
      fuzz/coverage and release-preflight; reconcile current status/queue documents.
- [ ] Prepare version-specific notes, checksums/SBOM/provenance plan and rollback steps.
Acceptance: evidence tied to immutable commits, remaining risks accepted by maintainer.
Publication/merge/tagging require separate authority; no external audit has occurred.

## Execution record

Phase 1 results and limitations: [REVIVAL_PHASE1_RESULTS.md](REVIVAL_PHASE1_RESULTS.md).
The tracked plan lives here because docs/superpowers/ is intentionally gitignored.
Phase 2 execution and limitations: [REVIVAL_PHASE2_RESULTS.md](REVIVAL_PHASE2_RESULTS.md).
Phase 3 remains explicitly deferred. Phase 4 execution is recorded in
[REVIVAL_PHASE4_PLAN.md](REVIVAL_PHASE4_PLAN.md); Phase 5 results: [REVIVAL_PHASE5_RESULTS.md](REVIVAL_PHASE5_RESULTS.md). Phase 6 remains follow-up work.

## Phase 2 execution design — 2026-11-16

Baseline: updated origin/main, 21340d31273442cf58d689aed7f5e36bf2b436f2
(PR #1 merged). Branch: codex/revival-phase2-io; target main.
Execute inline. Use a Linux-only LD_PRELOAD test DSO and a driver invoking actual
path APIs and CLI dispatch. No product target links hooks; no installed switches.
This avoids adding test conditionals to production I/O and intercepts libstdc++
file operations too. Windows/macOS retain portable tests; native fault injection
there remains a documented limitation.

- [x] Add deterministic one-shot hooks, assert each hook reached, run regressions
      against unchanged production code and record failures.
- [x] Fix only reproduced cleanup/reporting defects; re-run fault matrix.
- [x] Run full tests, provider inventory parity, policy/format/package and supported
      sanitizers; inspect existing platform CI coverage and record actual remote checks.
- [x] Review delta, document confirmed defects and untested risks, open focused PR:
      https://github.com/anothel/AnoSecureKit-Community/pull/2.

Review focus: fdopen ownership, post-commit unlink/sync errors, destination races,
short-write/EINTR handling, cleanup failure leaving sensitive temporary files.

## Phase 5 execution design — 2026-11-17

Baseline: fetched origin/main `cad3969edaa8c3ced29852ec2af68f217849548a`
(PR #4 merged). Branch: `codex/revival-phase5-cli`; execute inline as requested.
Preserve public APIs, formats, crypto/provider policy and existing key/file inputs.

Design decision: use explicit stdin-terminal `--password-prompt`, with no implicit
fallback, rather than opening a controlling terminal independently of stdin.
This makes pipe behavior deterministic on both POSIX and Windows. Prompt is a
single byte-oriented entry, with a 4096-byte bound and mode restoration via RAII.
Use native termios/Windows console modes. Typed cancellation is handled while
signal/processed input is disabled; external termination remains a limitation.
Add POSIX-only borrowed `--password-fd`, rejecting terminals and descriptor 0
when file data also uses stdin. Windows retains portable password files; CRT
inherited descriptors and key descriptors are deferred. Raw file/fd passwords
retain exact bytes and reject empty input. Every source conflicts with every
other source, with parsing completed before secret acquisition.

- [x] Add bounded portable subprocess and POSIX pseudo-terminal regressions;
      observe descriptor acceptance fail against the unchanged CLI.
- [x] Implement source selection, native no-echo entry and descriptor reading;
      run focused regressions and the full CTest suite.
- [x] Update checked help, CLI/security docs and regression expectations; run
      formatting, provider parity, package/consumer and policy checks.
- [x] Obtain fresh review, run native CI through focused PR and record actual
      outcomes/limitations in REVIVAL_PHASE5_RESULTS.md. No automatic merge.

Review focus: parse-before-read conflicts, stdin aliasing, exact binary input,
empty/EOF/cancel/overflow behavior, terminal restoration and diagnostic leakage.
Phase 3 remains deferred; no fuzz coverage completion is claimed.

Phase 5 PR: https://github.com/anothel/AnoSecureKit-Community/pull/5. Implementation
`c5219fe` plus test-only Windows newline correction `dd4c9d8` passed all 11 native
validation jobs in run 44020814789; release skipped. Local complete CTest 134/134,
provider parity, format 22.1.5, packages/consumers and document/boundary checks pass.
Remaining limits, including native Windows interactive-console coverage, are in
[REVIVAL_PHASE5_RESULTS.md](REVIVAL_PHASE5_RESULTS.md). Phase 3 remains deferred.
