<!-- SPDX-License-Identifier: MPL-2.0 -->
# Phase 6 — release engineering readiness

Assessment date: 2026-11-17. Branch: `codex/revival-phase6-readiness`.
Fetched origin/main: `98ddadd6f73659583e55314f7d91acb6ac9371b8` (PRs #1–#5 merged).
This document records that baseline plus this PR's documentation/preflight changes.
No production code, public signatures, formats, provider policy or version changed.

## Decision

**NO-GO for publication.** Local release engineering checks pass, but no maintainer
has selected the next version or authorized release, current alert validation is
blocked, and platform/compatibility evidence gaps remain. Phase 3 fuzz campaigns
and measured coverage are **DEFERRED**, not satisfied by unit tests or historical
fuzz smoke. A maintainer must resolve or explicitly accept gaps before a release.
This assessment is internal maintenance work, not an external security audit.

## Failure reproduction and correction

The unmodified preflight script on merged main fails at `README version example:
project(... VERSION 0.4.1)`. README closeout edits removed that example while the
validator retained it. Following that assertion exposed additional obsolete
requirements for a billing-blocked active queue and pre-closeout release-note
wording. These were documentation/validation drift, not package/runtime failures.

Restore an accurate README source-version statement; align roadmap/queue and
release-note assertions with resumed maintenance. Preserve exact CMake/source/tag
matching, SemVer, archive prefixes, source rebuilds, consumers, checksums, SBOM,
provenance wiring, provider boundaries and compatibility assertions. Negative
checks still reject a README version mutation and mismatching release tag.

Status, security support wording, prepared notes, provider evidence and Pages now
distinguish merged maintenance from historical July evidence. Source remains
0.4.1; it is not a decision to publish v0.4.1 or v0.5.0. The current notes section
is preparation only; maintainers must choose a version and review its exact notes.

## Evidence matrix

PASS means executed successfully here unless an immutable historical revision is
explicitly named. NOT TESTED includes unavailable/blocked work; it never means PASS.

| Gate | Result | Evidence / limits |
| --- | --- | --- |
| Original release-preflight documentation assertion | FAIL (reproduced) | Unmodified script, merged baseline; fixed in this PR |
| Full Release release-preflight | PASS | All dependencies and final script exit 0; GCC warnings-as-errors |
| Full OpenSSL CTest | PASS | 134/134, including POSIX CLI secret/output and Linux I/O fault matrices |
| External-provider parity | PASS | 134/134, identical ordered inventory; OpenSSL forwarding test provider only |
| Formatting | PASS | clang-format 22.1.5; no unrelated formatting edits |
| Package/install/consumer/source rebuild | PASS | ZIP/TGZ binary/source, installed CLI, current consumer, library-only install |
| Shared package/export/frozen-source consumer | PASS | Real ELF allowlist and current/frozen consumers via shared-package-check |
| Shared full CTest/export gate | PASS | 134/134; real ELF allowlist passes |
| Notes/version/workflow/policy/docs gates | PASS | Included in preflight; exact source version 0.4.1, no version bump |
| Rehearsal SHA256SUMS | PASS | 5/5: four archives plus asset SBOM; no checksum self-entry |
| Rehearsal SPDX SBOM | PASS | Asset inventory and SHA-256s; not a transitive dependency vulnerability scan |
| Provenance configuration | PASS | Tag-only release needs all native jobs; contents/id-token/attestations write scoped to release; dist/* attested |
| Wrong README version / mismatching tag rejection | PASS | Temporary-source mutation and v9.9.9 tag rejected; valid control passes |
| Existing native CI on this PR | NOT TESTED | Pending PR run; prior Phase 5 run is historical, not a current-head pass |
| New release assets / hosted attestation verification | NOT TESTED | No release/tag authorized; local staging is not publication evidence |
| Current security-alert inventory / revalidation | NOT TESTED (BLOCKED) | GitHub code-scanning API returned Forbidden; stopped |
| External security audit | NOT TESTED | None claimed |
| Windows interactive console | NOT TESTED | No native echo/mode/encoding/cancel tests; portable redirected tests are insufficient |
| Windows/macOS old-binary replacement | NOT TESTED | Frozen-source rebuilds do not prove existing binary replacement |
| Phase 3 fuzz campaigns / measured coverage | NOT TESTED — DEFERRED | Complete SKP1 fuzz-header skip and bounded KDF coverage remain open |

## Commands and environment

Linux x86_64, GCC 14.2.0/libstdc++, OpenSSL 3.5.7, CMake 3.31.6,
Ninja, Python 3.12.14, official GoogleTest 1.14.0 source already in build/_deps.
Use repository tools on PATH and clang-format 22.1.5 installed under /tmp.

```sh
export PATH=/workspace/.anosecurekit-tools/bin:$PATH
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
  -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON \
  -DCLANG_FORMAT_EXE=/tmp/phase6-format/clang_format/data/bin/clang-format
cmake --build build --target release-preflight format-check shared-package-check -j4
cmake -S . -B build-shared -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON \
  -DFETCHCONTENT_SOURCE_DIR_GOOGLETEST="$PWD/build/_deps/googletest-src"
cmake --build build-shared --target check shared-symbol-check -j4
(cd build/package-check/release-assets && sha256sum -c SHA256SUMS.txt)
```

Local logs: `/tmp/phase6-{preflight,final-gates,shared,negative}.log`.
Artifacts: `build/package-check/release-assets`, recipes under package-recipes.
These workspace paths are not durable published evidence. Source archives include
current working source; only a later authorized immutable tag can identify release
artifacts. The workflow requires both source formats and eight platform/package
pairs (16 binary archives), then an asset SBOM and checksum list. Local six-file
staging validates generation only, not the hosted 20-file publication contract.
Canonical extracted notes feed both create/edit through --notes-file; no generated
notes. Provenance verification requires actual hosted bundles and strict
repository/commit/ref/workflow checks after authorized publication.

## Unresolved security and compatibility risks

Reviewed CODEQL_TRIAGE_STATUS.md and RELEASE_AND_EVIDENCE_STATUS.md: July evidence
has 19 unique open alerts (16 high rule labels), historically classified 0 confirmed,
0 needs-review, 19 not-actionable. #2 concerns public SKP1 metadata; #3–#17 assume
operator-chosen local paths; #1/#18/#19 retain quality risks. Those are historical
static verdicts, not current clearance. Service/privileged embedding invalidates
local-operator assumptions. New/changed main flows and current alert inventory
need authorized review. The API request returned Forbidden even with the normal
network permission; no alternative credentials, identity, or access workaround
was attempted. No alerts were dismissed. Release tasks continued independently.

Native Windows prompt behavior, terminal restoration after external termination,
encoding and descriptor support remain gaps. Password files are portable;
descriptor input is explicitly unsupported on Windows. argv passwords remain
process-visible; memory erasure is not guaranteed. Linux fault injection does not
prove Windows MoveFileEx/macOS failures, real power loss, network filesystem or
adversarial directory behavior. Persistent unlink refusal may retain private temps;
post-commit errors may leave final output. stdout cannot be rolled back.

Phase 4's unchanged old consumer binary loaded the new ELF library on one matched
GCC/libstdc++/OpenSSL runtime. That historical test is not a current Windows/macOS
replacement test or cross-compiler/STL/CRT ABI guarantee. Export names/counts and
frozen-source consumers do not establish arbitrary layout or downstream private
symbol compatibility. No new ABI guarantee is made.

## Recovery and maintainer decisions

Before publication: choose version/support policy, review exact notes and current
alerts, resolve or accept platform gaps and Phase 3 deferral, verify native CI on
the final immutable main revision, then separately authorize tagging/publication.
If rehearsal fails, repair a focused branch and rerun gates. If a published build
fails, preserve existing tags, retain evidence, fix on main and choose a new
version; never silently replace consumed artifacts or move a published tag.
The release workflow supports same-tag upload reruns with --clobber; any such
recovery needs explicit maintainer authority and renewed integrity/provenance checks.
