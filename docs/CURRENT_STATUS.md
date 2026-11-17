<!-- SPDX-License-Identifier: MPL-2.0 -->
# AnoSecureKit Community Current Status

Status date: 2026-11-17. Maintenance resumed under [REVIVAL_PLAN.md](REVIVAL_PLAN.md).
Merged baseline: `98ddadd6f73659583e55314f7d91acb6ac9371b8` (PRs #1–#5).

Published release remains v0.4.0 at `694459ebe497d15ba75ef76a52fa7c36ddd7bcce`.
Current source version is 0.4.1, unpublished; the next release version requires an
explicit maintainer decision. No publication or tag action is authorized.

Merged maintenance includes private CLI output regressions, deterministic Linux
I/O fault tests and cleanup/error fixes, additive C++ file verification APIs,
shared export allowlists and installed/relocated consumers, and CLI password
file/descriptor/prompt sources. The selected API/ABI work from develop/v0.5.0 is
now integrated on main; it is absent from published v0.4.0.

Phase 6 evidence and GO / NO-GO decision are in
[REVIVAL_PHASE6_RESULTS.md](REVIVAL_PHASE6_RESULTS.md). Phase 3 fuzzing and measured
coverage remain **DEFERRED**. Historical results in release evidence documents
apply only to their named revisions.

OpenSSL 3.x is the only shipped Community production provider. External providers
are build-tree-only without fallback. Include root/namespace/CLI/package remain
anosecurekit; target remains anosecurekit::anosecurekit. SKT1/SKF1/SKP1 v1 bytes,
scrypt parameters and the `anosecurekit file sealing v1` label are preserved.

Published v0.4.0 generic CLI outputs may be 0644 under umask 022. The unpublished
main fix uses exclusive private temporary files (0600 maximum grant on POSIX).
Post-commit filesystem errors can leave output present; stream/stdout output
cannot be rolled back. Parent-directory and filesystem assumptions still apply.

The retained July triage classified 19 alerts as not actionable and left them
open. Current alert access is blocked; this is not current security clearance.
No external security audit, certification, FIPS/KCMVP status, secure-erasure
promise, support SLA or Enterprise alignment claim is made.
