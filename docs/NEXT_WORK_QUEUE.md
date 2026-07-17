<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Next Work Queue

Status: CURRENT
Baseline: post-`v0.4.0`

## Completed

### COMM-AUDIT-01 — Audit Post-v0.4.0 Current State

Result: COMPLETE

### COMM-DOC-01 — Establish Community CURRENT ONLY Documentation

Result: COMPLETE

Remote `main` now includes commit:

```text
2fa66fb2fc7d5449d57f615dbc3543c34e5077d9
```

### COMM-REL-01 — Audit v0.4.0 Publication Evidence

Result: COMPLETE WITH EXTERNAL EVIDENCE UNVERIFIED

Confirmed:

- `v0.4.0` resolves to `694459ebe497d15ba75ef76a52fa7c36ddd7bcce`;
- annotated tag identity and timestamp;
- project version `0.4.0`;
- current `main` is one documentation-only commit ahead of the release tag;
- the expected 20-file workflow publication contract.

Not recovered:

- authoritative GitHub Release object and publication time;
- actual asset inventory, sizes and digests;
- published `SHA256SUMS.txt` and SPDX SBOM;
- artifact-attestation results;
- exact tag-push CI, CodeQL, Windows and macOS results.

No tag or Release mutation was performed.

## COMM-REL-02 — Recover Authenticated Hosted Publication Evidence

Priority: P0

Run the read-only evidence collector from an authenticated GitHub CLI
environment and retain the output for the exact release commit.

Required outcomes:

1. Resolve the Release REST object or record an authoritative API 404.
2. Record complete asset names, sizes, content types and GitHub digest fields.
3. Download all assets and verify `SHA256SUMS.txt`.
4. Compare the SPDX SBOM package/checksum inventory with downloaded assets.
5. Verify GitHub artifact attestations.
6. Record tag-push Actions runs, jobs, conclusions and artifact inventory.
7. Record CodeQL analysis for the exact release commit, if one exists.
8. If a billing, authorization, retention or service blocker is proven, record the
   exact blocker and classify the affected evidence `DEFERRED`.

Do not move or recreate `v0.4.0`. Do not create or repair a Release without a
separate explicit authorization.

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

- Keep `v0.4.0` as the current release code/tag baseline.
- Keep the post-tag documentation commit on `main`; do not describe it as part of
  the `v0.4.0` release assets.
- Do not move or recreate `v0.4.0`.
- Use `v0.4.1` for a source, workflow, packaging, documentation, or maintenance
  change that requires a new release.
- Use `v0.5.0` only for intentional public product evolution.
- Do not change `SKT1`, `SKF1`, or `SKP1` v1 meaning in either line.
