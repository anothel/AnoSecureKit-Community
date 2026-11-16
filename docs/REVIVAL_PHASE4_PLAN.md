<!-- SPDX-License-Identifier: MPL-2.0 -->
# Phase 4 API and ABI integration plan

Execute inline using superpowers:executing-plans. User explicitly authorized
resuming this phase and opening focused PRs; no new design approval is needed.

Baseline: main `0cb8bda7b6d96a11bd83228321707f83d62daa4c` (Phase 2 merged).
Candidate reviewed: `9fe79dc1e0f8b9951e86c2707c70469611ab43e4`.
Spec: AGENTS.md, REVIVAL_PLAN.md Phase 4, FORMAT.md, SECURITY_MODEL.md.
Goal: additive file verification and explicit shared-library export gates.
Status: API #3 merged externally; ABI #4 targets main with implementation CI
passing at e5e3d39. No merge or release was performed by this task.
Preserve all existing APIs, package names, v1 bytes, KDF settings and providers.
Phase 3 is deferred; no merge, release, tag change or alert dismissal.

## Task 1 — file verification API PR

- [x] Watch new verification tests fail to link before implementation.
- [x] Add path/istream overloads of `verify_file(input, key, aad={})` and
  `verify_file_with_password(input, password, aad={})`, returning void and
  preserving open-file errors. Reuse the existing reader and its chunk wipe
  guards through a private discard stream; do not duplicate parsing or crypto.
- [x] Cover zero/exact/multiple chunk lengths, wrong credentials/AAD, late
  tampering, truncation/trailing input, all SKF1/SKP1 fixtures, invalid password,
  missing paths and read errors. Assert path verification leaves no output.
- [x] Pin header signatures and exercise installed consumer overloads.
- [x] Run check, CTest, format, package, parity and boundary/document checks;
  record real results and limitations (see REVIVAL_PHASE4_API_RESULTS.md).
  Commit, push and open PR against main after final review.

## Task 2 — shared ABI PR

Consumes the Task 1 API. Initially stack this focused PR on Task 1; both descend
from latest main at task start. After the external merge of #3, retarget #4 to
main; its review delta remains the ABI integration only.

- [x] Run the candidate symbol gate against a current shared build and observe
  rejection of internal exports before applying visibility changes.
- [x] Adapt candidate export annotations, hidden visibility, allowlist and clean
  installed shared consumer gate. Preserve all public signatures/class layouts.
- [x] Test allowlist rejection of missing and unexpected exports, and Windows
  export inventory rather than relying only on token substring presence.
- [x] Compile a consumer with baseline headers/library, run its unchanged binary
  against the new DSO, and recompile old source against installed new headers.
- [x] Wire Linux/Windows shared checks to CI, rerun suites/package/parity and
  document ABI policy and compiler limits; record remote results against tested commits.
- [x] Review complete delta, publish the focused PR and verify native CI; never merge.

## Review focus

Verification must read through the final record, reject trailing data and discard
all plaintext internally. No filesystem output or output callback is accepted.
Password bytes, generic errors and caller OpenSSL provider context must survive.
Cross-DSO typed catches, exception RTTI, old packet object lifecycle and installed
consumers must work. Symbol gates must reject unrelated or extra exports.

## Decisions from candidate review

Reuse stream `open_file` to avoid a second parser; retain Phase 2 I/O changes.
Retain current CLI verification routing and diagnostics (the candidate changed
missing-input diagnostics); the public API is additive. Initially exclude
candidate string-construction rewrites; Clang CI later proved
they are needed to prevent a default-visible STL instantiation, so include only
those two equivalent message constructions. Skip historical release/status edits.
No version bump.
The export allowlist is a surface inventory, not a universal binary compatibility
promise: old binaries are tested only on the same local compiler/runtime.
