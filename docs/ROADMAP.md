<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Roadmap

This compatibility roadmap records the active work queue. The canonical numbered
queue is `docs/NEXT_WORK_QUEUE.md`.

## Intake Rules

- Active roadmap items must name an existing AnoSecureKit surface: public C++ API,
  CLI, `SKT1`/`SKF1`/`SKP1`, CMake package, provider seam, release asset, or
  security-reporting surface.
- External audit or roadmap notes are triage input only until mapped to a current
  repository surface and a regression check.
- Node.js and backend middleware are outside this C++ Community repository unless
  an existing public package or release contract requires a focused change.
- Keep v0.x public API changes minimal.
- Release-impacting work must name a check and rollback path.
- Do not leave accepted fixes deferred; move them to the Fix Queue with an owner,
  protected surface, and validation command.
- `dogfood-check` results should create work only after no repeated friction is
  disproved by a reproducible issue.

## Current Plan

### Now

COMM-REL-01 — v0.4.0 publication evidence:

- Confirm the GitHub Release, asset inventory, checksums, SBOM, attestations,
  hosted CI, CodeQL, and claimed platform evidence for the exact tag commit.
- Keep unavailable evidence `UNVERIFIED` or `DEFERRED`.
- check: compare the tag commit, release metadata, `SHA256SUMS.txt`, SBOM,
  attestation verification, and hosted run conclusions
- rollback: remove or correct only the unsupported publication claim; do not move
  or recreate `v0.4.0`

COMM-VER-01 — provider parity evidence:

- Re-run the same discovered inventory through the OpenSSL and external
  assemblies and retain machine-readable output.
- check: `cmake --build build --config Release --target release-preflight`
- rollback: keep the historical 124/124 statement as `RECORDED` and do not claim
  a current `PASS`

### Package Publishing

- Package-manager recipe publication remains an external channel handoff.
- Use recipe drafts only after the matching GitHub Release assets are uploaded,
  checksum-verified, attested, and consumer-tested.
- check: consumer project builds against each published recipe
- rollback: remove or replace the package recipe update if checksum or consumer
  verification fails

### Fix Queue

- Keep release hygiene gates, provider-boundary gates, and v1 fixtures aligned
  with the current public surface.
- Prevent EOL-only worktree drift before source-archive generation.
- Refresh hosted GCC, Clang, MSVC, AppleClang, sanitizer, package, and CodeQL
  evidence.
- Turn accepted external-review findings into one protected change each.

Completed implementation history belongs in Git history and
`docs/RELEASE_NOTES.md`, not in this active roadmap.
