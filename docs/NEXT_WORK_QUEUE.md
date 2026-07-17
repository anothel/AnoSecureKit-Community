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
- `COMM-CODEQL-01`: exact-commit CodeQL static triage — COMPLETE
- `COMM-CODEQL-02`: alert disposition and status documentation — COMPLETE

### COMM-FUZZ-01 Closeout

Implementation commit:

```text
c3872c196452b561b1a545ee73204dca0df83dc7
fix: normalize hex fixtures in fuzz adapter
```

Focused and full local fuzz validation, general CTest 124/124, backend, package,
install, export, source rebuild, and consumer checks passed. Hosted confirmation
is `DEFERRED_EXTERNAL` because GitHub Actions billing prevents runner execution.

### COMM-HYG-01 Closeout

The current source tree has deterministic LF policy, compact evidence retention,
CPack evidence exclusions, and package-check regression protection. Git history
was not rewritten.

### COMM-CODEQL-01/02 Closeout

```text
analysis IDs: 1471089159, 1471719182
results per analysis: 19
SARIF relation: byte-identical
unique alerts: 19
confirmed: 0
needs_review: 0
not_actionable: 19
```

Alert `#2` is a public-metadata misclassification. Alerts `#3`–`#17` do not cross
a supported external-attacker boundary in the current local CLI product model.
Alerts `#1`, `#18`, and `#19` are non-security correctness or maintainability
results. All GitHub alerts remain open; no dismissal or state update was
performed.

## COMM-VER-01 — Reproduce Provider Parity Evidence

Priority: P1

Run the same discovered test inventory through the shipped OpenSSL assembly and
the externally injected assembly. Retain machine-readable CTest/JUnit evidence,
exact toolchain/OpenSSL versions, inventory comparison, and command transcript.
Hosted execution may remain `DEFERRED_EXTERNAL` while billing is blocked, but a
local reproducible run can close the evidence gap.

## COMM-REL-03 — Make Publication Evidence Self-Contained

Priority: P1

Retain the successful `gh 2.95.0` attestation outputs beside the external evidence
archive and verify Release body parity. Keep only compact repository-safe
summaries in source control.

## COMM-DOC-02 — Close Website And Repository Drift

Priority: P1

Align GitHub Pages HTML with canonical Markdown status and replace candidate-era
wording. Keep `docs/ROADMAP.md` as a compatibility entry point without creating a
second independent queue.

## COMM-CODEQL-03 — Apply GitHub Alert Dispositions

Priority: OPTIONAL / REQUIRES EXPLICIT AUTHORIZATION

Only after reviewing the rule-level triage table, optionally update GitHub alert
states with one reason and comment per alert. Do not bulk-dismiss solely from
severity labels or the aggregate `not_actionable` count. Keeping the alerts open
is acceptable.

## COMM-PLAT-01 — Refresh Hosted Platform Matrix

Priority: P2 / DEFERRED_EXTERNAL while billing is blocked

The v0.4.0 Windows/macOS lanes are verified. Re-run current hosted lanes only when
runner billing is restored or platform requirements change.

## COMM-SEC-01 — Security Review Readiness

Priority: P2

After provider parity evidence is current, prepare the public source for focused
external review. The CodeQL triage found no confirmed Community security finding,
but this is not an external audit conclusion.

## Version Direction

- Keep `v0.4.0` as the published release baseline.
- Do not move or recreate `v0.4.0`.
- Use `v0.4.1` when the fuzz fix and maintenance changes are published.
- Use `v0.5.0` only for intentional public product evolution.
- Do not reinterpret `SKT1`, `SKF1`, or `SKP1` v1.
