<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Repository Hygiene

Status: CURRENT

## Line Endings

`.gitattributes` is the source of truth for checkout normalization.

- Source code, CMake, Markdown, HTML, JSON, YAML, shell scripts, and fixtures use LF.
- Future `.bat` and `.cmd` files may use CRLF.
- Binary formats are marked binary and are never text-normalized.
- Do not commit line-ending-only changes mixed with semantic changes.

After adding or changing normalization policy, review before committing:

```sh
git add --renormalize .
git status --short
git diff --cached --check
```

A release starts only from a clean tracked worktree.

## Evidence Retention

The source repository retains compact versioned summaries under `artifacts/`.
It does not retain:

- downloaded release binaries;
- expanded release archives;
- authenticated API response dumps;
- transient runner logs;
- local evidence ZIP copies;
- credentials or authentication status containing sensitive details.

Full release assets belong in GitHub Releases. Complete audit bundles are stored
outside the source tree with an exact SHA-256 recorded in the compact summary.
Git history is not rewritten merely to remove a file from the current tree.

## Source Packages

CPack source archives must exclude:

```text
artifacts/
COMM-REL-*-evidence/
COMM-REL-*.zip
COMM-REL-*.zip.sha256
collect_v*-publication-evidence*.sh
```

`tests/package/check_package.cmake` rejects a source archive that contains these
repository-external evidence paths.

## Sharing a Current Source Snapshot

Prefer a tracked source snapshot rather than compressing the whole working
directory:

```sh
git archive --format=zip --output=AnoSecureKit-Community-main.zip HEAD
```

This avoids local build directories, untracked evidence, and ignored files.
