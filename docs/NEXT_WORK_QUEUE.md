<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Next Work Queue

Status: CURRENT
Baseline: post-`v0.4.0`

## Completed

### COMM-AUDIT-01 — Audit Post-v0.4.0 Current State

Result: COMPLETE

### COMM-DOC-01 — Establish Community CURRENT ONLY Documentation

Result: COMPLETE

### COMM-REL-01 — Audit v0.4.0 Publication Evidence

Result: COMPLETE

### COMM-REL-02 — Recover Authenticated Hosted Publication Evidence

Result: COMPLETE WITH ONE SCHEDULED FUZZ FAILURE

Confirmed:

- public `v0.4.0` Release object, exact title, state, and publication time;
- 20/20 expected release assets and matching API/download inventory;
- `SHA256SUMS.txt` 19/19;
- SPDX release SBOM 18/18;
- GitHub digest 20/20;
- supplementary attestation verification 20/20;
- successful v0.4.0 tag workflow with 10/10 jobs;
- Windows 4/4 and macOS 2/2 jobs;
- two successful exact-commit CodeQL analyses.

Open items discovered by the evidence review:

- scheduled fuzz run `29334006653` failed;
- CodeQL `results_count=19` per analysis has not been triaged;
- the evidence archive itself records attestation as `DEFERRED_GH_VERSION`, while
  the successful supplementary verification was performed separately;
- Release body parity with `docs/RELEASE_NOTES.md` was not assessed.

## COMM-FUZZ-01 — Fix SKT1 Fuzz Invalid-Input Escape

Priority: P0

Reproduce and fix the scheduled fuzz failure without changing production format
semantics or accepting malformed input.

Required outcomes:

1. Reproduce the odd-length hex input path that throws
   `anosecurekit::error("hex input must contain an even number of characters")`.
2. Keep production `hex_decode` strict and fail-closed.
3. Prevent expected invalid-input exceptions from escaping the libFuzzer target.
4. Limit exception handling to the fuzz adapter/target boundary rather than
   weakening public API behavior.
5. Add a regression seed or focused harness test for odd-length and malformed hex.
6. Run all configured fuzz smoke targets and retain logs.
7. Confirm no public API, CLI, CMake identity, fixture, or `SKT1`/`SKF1`/`SKP1`
   v1 meaning changes.

Do not suppress unexpected exceptions, sanitizer findings, memory errors, or
format invariant violations.

## COMM-CODEQL-01 — Triage Exact-Commit CodeQL Results

Priority: P1

Retrieve and classify the 19 results reported by each exact-commit analysis.
Determine whether they are active alerts, duplicate SARIF results, dismissed
findings, generated-code noise, or actionable Community defects. Workflow
success alone is not a zero-alert conclusion.

## COMM-VER-01 — Reproduce Provider Parity Evidence

Priority: P1

Run the exact same discovered test inventory through:

1. the shipped OpenSSL assembly;
2. the externally injected provider assembly.

Retain CTest/JUnit output, environment versions, and inventory comparison for the
exact commit. Historical 124/124 remains `RECORDED` until reproduced or the
original machine-readable evidence is recovered.

## COMM-REL-03 — Make Publication Evidence Self-Contained

Priority: P1

Retain the successful `gh 2.95.0` attestation outputs with the evidence archive,
verify Release body parity, and store a compact repository-safe evidence summary.
Do not commit credentials, transient runner data, or all release binaries to the
source repository.

## COMM-DOC-02 — Close Website and Repository Drift

Priority: P1

Keep Markdown and GitHub Pages status text aligned and ensure release pages point
to verified publication evidence.

## COMM-HYG-01 — Prevent EOL-Only Worktree Drift

Priority: P1

Define and verify repository line-ending policy. Start releases from a clean
worktree and confirm source-archive checksums are generated only after line-ending
normalization is stable.

## COMM-PLAT-01 — Refresh Hosted Platform Matrix

Priority: P2

The v0.4.0 exact-commit Windows/macOS lanes are now verified. Refresh the declared
support matrix only when compiler, OpenSSL, runner, sanitizer, or packaging
requirements change.

## COMM-SEC-01 — Security Review Readiness

Priority: P2

After fuzz, CodeQL triage, and provider parity are current, prepare the released
source and public surfaces for the focused process in
`docs/EXTERNAL_SECURITY_REVIEW.md`. Do not claim an audit before an external
review report exists.

## Version Direction

- Keep `v0.4.0` as the current published release baseline.
- Do not move or recreate `v0.4.0`.
- Fix the fuzz harness on `main`.
- Use `v0.4.1` if the fuzz fix or another source/workflow maintenance change is
  published as a release.
- Use `v0.5.0` only for intentional public product evolution.
- Do not change `SKT1`, `SKF1`, or `SKP1` v1 meaning in either line.
