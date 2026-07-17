<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Next Work Queue

Status: CURRENT
Baseline: post-`v0.4.0`

## COMM-REL-01 — Confirm v0.4.0 Publication Evidence

Priority: P0

Confirm for commit `694459ebe497d15ba75ef76a52fa7c36ddd7bcce`:

- GitHub Release identity and publication timestamp;
- exact release asset inventory;
- `SHA256SUMS.txt` verification;
- SPDX release SBOM;
- artifact attestations;
- hosted CI and CodeQL conclusions;
- Windows and macOS evidence where claimed.

Until confirmed, keep those items `UNVERIFIED`. Do not move or recreate the
existing tag merely to repair missing evidence.

## COMM-VER-01 — Reproduce Provider Parity Evidence

Priority: P1

Run the exact same discovered test inventory through:

1. the shipped OpenSSL assembly;
2. the externally injected provider assembly.

Retain CTest/JUnit output, environment versions, and inventory comparison for the
exact commit. The historical 124/124 statement remains `RECORDED` until this is
reproduced or the original evidence is recovered.

## COMM-DOC-02 — Close Website and Repository Drift

Priority: P1

Keep Markdown and GitHub Pages status text aligned. Remove candidate-era wording
and ensure release pages point to evidence rather than assuming publication.

## COMM-HYG-01 — Prevent EOL-Only Worktree Drift

Priority: P1

Define and verify repository line-ending policy. Start releases from a clean
worktree, and confirm source-archive checksums are generated only after EOL
normalization is stable.

## COMM-PLAT-01 — Refresh Hosted Platform Matrix

Priority: P1

Reconfirm supported GCC, Clang, MSVC, AppleClang, OpenSSL, sanitizer, install,
consumer, package, and CodeQL lanes. Record unavailable hosted lanes as
`DEFERRED`, not `PASS`.

## COMM-SEC-01 — Security Review Readiness

Priority: P2

After release evidence is complete, prepare the current released source and its
public surfaces for the focused process in `docs/EXTERNAL_SECURITY_REVIEW.md`.
Do not claim an audit before a completed external review report exists.

## Version Direction

- Keep `v0.4.0` as the current code/tag baseline.
- Do not move or recreate `v0.4.0`.
- Use `v0.4.1` for a source, workflow, packaging, documentation, or maintenance
  change that requires a new release.
- Use `v0.5.0` only for intentional public product evolution.
- Do not change `SKT1`, `SKF1`, or `SKP1` v1 meaning in either line.
