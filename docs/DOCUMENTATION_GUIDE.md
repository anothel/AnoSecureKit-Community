<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Documentation Guide

`docs/DOCUMENT_INDEX.md` is the canonical document map. This compatibility entry
point remains because release checks and existing links use it.

Historical implementation plans stay in Git history or versioned evidence, not
in current user documentation.

## Canonical User Docs

- `README.md`
- `docs/CLI.md`
- `docs/FORMAT.md`
- `docs/SECURITY_MODEL.md`
- `docs/LICENSE_POLICY.md`
- `docs/VERIFY_RELEASE.md`

## Canonical Current Maintainer Docs

- `docs/CURRENT_STATUS.md`
- `docs/CROSS_REPOSITORY_BOUNDARY.md`
- `docs/BACKEND_AND_PROVIDER_CONTRACT.md`
- `docs/RELEASE_AND_EVIDENCE_STATUS.md`
- `docs/DOCUMENT_INDEX.md`
- `docs/NEXT_WORK_QUEUE.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/RELEASE_NOTES.md`

Focused policy documents remain listed in `docs/DOCUMENT_INDEX.md`.

## Update Rules

- CLI behavior changes must update `docs/CLI.md` and keep `cli-docs-check`
  passing.
- Serialized byte-format changes must update `docs/FORMAT.md`, fixtures, and
  fixture inventory documents in the same change.
- Status claims must distinguish `PASS`, `RECORDED`, `UNVERIFIED`, and `DEFERRED`.
- New public source-controlled text files must include
  `SPDX-License-Identifier: MPL-2.0`.
