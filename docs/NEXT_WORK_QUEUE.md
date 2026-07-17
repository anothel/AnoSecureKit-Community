<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Next Work Queue

Status: CURRENT
Baseline: post-`v0.4.0`

## Completed

- `COMM-AUDIT-01`: post-v0.4.0 current-state audit — COMPLETE
- `COMM-DOC-01`: CURRENT ONLY documentation — COMPLETE
- `COMM-REL-01`: publication evidence audit — COMPLETE
- `COMM-REL-02`: authenticated publication evidence recovery — COMPLETE
- `COMM-FUZZ-01`: SKT1 fuzz invalid-input escape — COMPLETE LOCAL
- `COMM-HYG-01`: line-ending and evidence-retention hygiene — COMPLETE

### COMM-FUZZ-01 Closeout

Implementation commit:

```text
c3872c196452b561b1a545ee73204dca0df83dc7
fix: normalize hex fixtures in fuzz adapter
```

Local verification:

- exact crash fixture and existing odd-length seed passed;
- five configured fuzz targets passed without sanitizer findings;
- general CTest passed 124/124;
- backend boundary, external hook, package, install, export, source rebuild, and
  consumer checks passed;
- public API, CLI, CMake identity, fixtures, and v1 format meaning were unchanged.

Hosted confirmation is `DEFERRED_EXTERNAL` because GitHub Actions billing prevents
runner execution. Do not reopen the production parser or weaken strict hex
validation to compensate for the unavailable hosted lane.

### COMM-HYG-01 Closeout

- deterministic LF policy added through `.gitattributes`;
- full release evidence and binaries removed from the current source tree;
- compact versioned evidence summaries retained under `artifacts/`;
- root evidence outputs ignored;
- CPack source archives exclude evidence paths;
- package-check rejects regressions that reintroduce those paths;
- Git history was not rewritten.

## COMM-CODEQL-01 — Triage Exact-Commit CodeQL Results

Priority: P1

Retrieve and classify the 19 results reported by each exact-commit analysis.
Determine whether they are active alerts, duplicate SARIF results, dismissed
findings, generated-code noise, or actionable Community defects. Workflow
success alone is not a zero-alert conclusion.

## COMM-VER-01 — Reproduce Provider Parity Evidence

Priority: P1

Run the same discovered test inventory through the shipped OpenSSL assembly and
the externally injected assembly. Retain machine-readable CTest/JUnit evidence.
Hosted execution may remain `DEFERRED_EXTERNAL` while billing is blocked, but a
local reproducible run can still close the evidence gap.

## COMM-REL-03 — Make Publication Evidence Self-Contained

Priority: P1

Retain the successful `gh 2.95.0` attestation outputs beside the external evidence
archive and verify Release body parity. Keep only compact repository-safe
summaries in source control.

## COMM-DOC-02 — Close Website And Repository Drift

Priority: P1

Align GitHub Pages HTML with the canonical Markdown status and replace candidate-
era wording. Keep `docs/ROADMAP.md` as a compatibility entry point without
creating a second independent queue.

## COMM-PLAT-01 — Refresh Hosted Platform Matrix

Priority: P2 / DEFERRED_EXTERNAL while billing is blocked

The v0.4.0 Windows/macOS lanes are verified. Re-run current hosted lanes only
when runner billing is restored or platform requirements change.

## COMM-SEC-01 — Security Review Readiness

Priority: P2

After CodeQL triage and provider parity evidence are current, prepare the public
source for focused external review. Do not claim an audit before a completed
external report exists.

## Version Direction

- Keep `v0.4.0` as the published release baseline.
- Do not move or recreate `v0.4.0`.
- Use `v0.4.1` when the fuzz fix and maintenance changes are published.
- Use `v0.5.0` only for intentional public product evolution.
- Do not reinterpret `SKT1`, `SKF1`, or `SKP1` v1.
