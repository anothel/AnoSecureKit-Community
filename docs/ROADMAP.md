<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Roadmap

Status: COMPATIBILITY ENTRY POINT

The canonical active queue is [`docs/NEXT_WORK_QUEUE.md`](NEXT_WORK_QUEUE.md).
This file exists for stable links and release checks; it must not carry a second
independent task list. Website-only planning lives in
[`docs/WEB_ROADMAP.md`](WEB_ROADMAP.md).

## Current Direction

- Keep `v0.4.0` as the published release baseline.
- Prepare `v0.4.1` as a maintenance release for the reviewed fuzz fix and
  evidence/documentation work.
- Keep OpenSSL 3.x as the only shipped Community production provider.
- Keep the external provider seam build-tree-only with no silent fallback.
- Preserve the public API, CLI, CMake identity, fixtures, and
  `SKT1`/`SKF1`/`SKP1` v1 meanings.
- Keep Enterprise proprietary code and the AnoCrypto-C adapter outside Community.
- Record hosted current-main checks as `DEFERRED_EXTERNAL_BILLING` while runner
  billing is blocked.

## Intake Rules

New work belongs in `docs/NEXT_WORK_QUEUE.md` only when it names a current public
or release surface, a concrete problem, a runnable check, and a rollback path.
Completed work belongs in release notes, focused status documents, or Git history.
