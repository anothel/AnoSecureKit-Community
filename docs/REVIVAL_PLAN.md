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

## Phase 1 — verify maintenance security (verified locally; PR access blocked)

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
- [ ] Commit and open focused PR when GitHub access permits.

Acceptance: matrix plus existing suite pass, no API/format drift, reproducible
results with explicit limitations. Tests verifying existing fixes may pass first.
Risks: filesystem assumptions, Windows untested locally, fault paths not injected.

## Phase 2 — file I/O fault injection (separate PR)

Files: src/file_io.cpp, src/cli/commands.cpp, tests/file_test.cpp and new test-only
fault harness under tests/. Preserve public interfaces; use test link wrappers or
an internal seam, never public production switches.
- [ ] Write failing cases for open/fdopen, read, short write/EINTR, flush/fsync,
      close, link/rename, temp unlink and parent directory sync failures.
- [ ] Assert generic error categories, descriptor closure, owned-temp cleanup and
      preservation of pre-existing files; post-commit sync failure may leave output.
- [ ] Reproduce any defect, minimally fix it, run suite/parity and commit.
Acceptance: deterministic failure matrix for CLI and path APIs; no timing-only tests.
Risk: fdopen/allocation failures and cleanup failure need explicit ownership checks;
      CLI and library durability guarantees differ.

## Phase 3 — targeted fuzzing and coverage (separate PR)

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
- [ ] Obtain exact branch and compare with reviewed Phase 1 baseline; do not merge blindly.
- [ ] Review verification APIs, error behavior and discarded plaintext ownership.
- [ ] Test old consumers, header compatibility, shared exports and ABI allowlist on
      Linux/Windows; rerun format fixtures, installed packages and ordered parity.
Acceptance: additive APIs only, explicit ABI decision and no lost maintenance fixes.
Risk: candidate not present in initial checkout; ABI/platform behavior needs CI.

## Phase 5 — CLI secret handling (separate PR)

Files: src/cli/commands.cpp, docs/CLI.md, tests/cli/.
- [ ] Specify optional file/descriptor/prompt input with precedence and stdin conflicts.
- [ ] Test exact password bytes, empty inputs, no echo/log disclosure and error paths.
- [ ] Preserve existing options; document argv/process-list exposure and memory limits.
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
Phases 2–6 are prepared follow-up work, not executed in this Phase 1 change.
