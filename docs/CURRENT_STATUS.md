<!-- SPDX-License-Identifier: MPL-2.0 -->
# AnoSecureKit Community Current Status

Status date: 2026-11-25 (KST). Maintenance resumed under [REVIVAL_PLAN.md](REVIVAL_PLAN.md).
Reviewed main baseline: `02704c48f0e6151b117b37ee3412494346cebd60`.

Published release remains v0.4.0 at `694459ebe497d15ba75ef76a52fa7c36ddd7bcce`.
Current source version is 0.4.1, unpublished; the next release version requires an
explicit maintainer decision. No publication or tag action is authorized.

Merged maintenance includes private CLI output regressions, deterministic Linux
I/O fault tests and cleanup/error fixes, additive C++ file verification APIs,
shared export allowlists and installed/relocated consumers, and CLI password
file/descriptor/prompt sources. The selected API/ABI work from develop/v0.5.0 is
now integrated on main; it is absent from published v0.4.0.

Phase 3 **bounded verification is complete**. Six 60-second fuzz campaigns
recorded 480,379 executions. Full-suite coverage measured 1842/1983 lines and
1748/2605 branches. See the [Phase 3 evidence](COVERAGE.md#phase-3-bounded-verification)
for exact revisions, runs and limits. Phase 6 assessed release readiness separately
in [REVIVAL_PHASE6_RESULTS.md](REVIVAL_PHASE6_RESULTS.md). Historical results apply
only to their named revisions. Independent security review and application-level
handling of partial stdout remain open. See [issue #8](https://github.com/anothel/AnoSecureKit-Community/issues/8).

OpenSSL 3.x is the only shipped Community production provider. External providers
are build-tree-only without fallback. Include root/namespace/CLI/package remain
anosecurekit; target remains anosecurekit::anosecurekit. SKT1/SKF1/SKP1 v1 bytes,
scrypt parameters and the `anosecurekit file sealing v1` label are preserved.

Published v0.4.0 generic CLI outputs may be 0644 under umask 022. The unpublished
main fix uses exclusive private temporary files (0600 maximum grant on POSIX).
Post-commit filesystem errors can leave output present; stream/stdout output
cannot be rolled back. Parent-directory and filesystem assumptions still apply.

The retained July triage classified 19 alerts as not actionable and left them
open. Current CodeQL alert status and count are unknown because alert access is
blocked. See [issue #10](https://github.com/anothel/AnoSecureKit-Community/issues/10).
No external security audit, certification, FIPS/KCMVP status, secure-erasure
promise, support SLA or Enterprise alignment claim is made.
