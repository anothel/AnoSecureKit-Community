<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Roadmap

Status: COMPATIBILITY ENTRY POINT

The canonical queue is [`docs/NEXT_WORK_QUEUE.md`](NEXT_WORK_QUEUE.md), and it is
closed. This file remains for stable links and release checks; it is not an
independent task list.

## Closeout Direction

```text
ENGINEERING_STATUS=CLOSED_AND_FROZEN
ACTIVE_NEXT_WORK=NONE
ACTIVE_RELEASE_ACTION=NONE
FUTURE_WORK=DEFERRED_NOT_SELECTED
```

- Keep `v0.4.0` as the published release baseline.
- Keep source version `0.4.1` unpublished and parked.
- Keep `develop/v0.5.0` parked and unmerged.
- Keep OpenSSL 3.x as the only shipped Community production provider.
- Keep the external provider seam build-tree-only with no silent fallback.
- Preserve the public API, CLI, CMake identity, fixtures, and
  `SKT1`/`SKF1`/`SKP1` v1 meanings.
- Keep Enterprise proprietary code and the AnoCrypto-C adapter outside
  Community.

There is no active roadmap. Deferred product, security, distribution, and web
ideas are not selected work. Reopening requires a new explicit product decision;
completed work remains in release notes, focused status documents, or Git
history. Website notes in [`docs/WEB_ROADMAP.md`](WEB_ROADMAP.md) are also
closed and deferred.
