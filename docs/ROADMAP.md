<!-- SPDX-License-Identifier: MPL-2.0 -->
# AnoSecureKit Community Roadmap

Status: COMPATIBILITY ENTRY POINT

The canonical queue is [docs/NEXT_WORK_QUEUE.md](NEXT_WORK_QUEUE.md). This page
must not carry a second task list. The active execution record is
[REVIVAL_PLAN.md](REVIVAL_PLAN.md).

## Current Direction

PRs #1–#5 are merged. Phase 6 records release engineering and remaining risks.
Phase 3 fuzzing and coverage remain DEFERRED. The next release version requires
an explicit maintainer decision; current source 0.4.1 is unpublished.
Keep OpenSSL 3.x as the only shipped Community production provider, the external
seam build-tree-only without fallback, and preserve public identities and v1 formats.

## Release Verification Entry Point

```sh
cmake --build build --config Release --target release-preflight
```

See [REVIVAL_PHASE6_RESULTS.md](REVIVAL_PHASE6_RESULTS.md) for evidence and gaps.

## Intake Rules

New work needs a scope, a runnable check, and a rollback path. Maintenance does
not authorize publication, tag changes, alert dismissal, or a support SLA.
