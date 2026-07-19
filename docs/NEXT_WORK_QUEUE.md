<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Next Work Queue

Status: CURRENT
Baseline: post-`v0.4.0`

## Completed

- `COMM-AUDIT-01`: post-v0.4.0 current-state audit — COMPLETE
- `COMM-DOC-01`: CURRENT ONLY documentation — COMPLETE
- `COMM-REL-01`: publication evidence audit — COMPLETE
- `COMM-REL-02`: authenticated publication evidence recovery — COMPLETE
- `COMM-REL-03`: self-contained publication evidence — COMPLETE
- `COMM-FUZZ-01`: SKT1 fuzz invalid-input escape — COMPLETE LOCAL
- `COMM-HYG-01`: line-ending and evidence-retention hygiene — COMPLETE
- `COMM-CODEQL-01`: exact-commit CodeQL static triage — COMPLETE
- `COMM-CODEQL-02`: alert disposition and status documentation — COMPLETE
- `COMM-VER-01`: provider parity machine-readable local reproduction — COMPLETE LOCAL WITH HARNESS CAVEAT
- `COMM-VER-02`: exact GoogleTest provider parity — COMPLETE LOCAL EXACT
- `COMM-DOC-02`: GitHub Pages and canonical documentation alignment — COMPLETE
- `COMM-REL-04A`: prepare and commit v0.4.1 maintenance source — COMPLETE LOCAL
- `COMM-PROD-01`: product capability and gap audit — COMPLETE
- `COMM-HARD-02`: secure CLI output creation — COMPLETE LOCAL

### COMM-FUZZ-01 Closeout

Implementation commit:

```text
c3872c196452b561b1a545ee73204dca0df83dc7
fix: normalize hex fixtures in fuzz adapter
```

Focused and full local fuzz validation, general CTest 124/124, backend, package,
install, export, source rebuild, and consumer checks passed. Hosted confirmation
is `DEFERRED_EXTERNAL` because GitHub Actions billing prevents runner execution.

### COMM-HYG-01 Closeout

The current source tree has deterministic LF policy, compact evidence retention,
CPack evidence exclusions, and package-check regression protection. Git history
was not rewritten.

### COMM-CODEQL-01/02 Closeout

```text
analysis IDs: 1471089159, 1471719182
results per analysis: 19
SARIF relation: byte-identical
unique alerts: 19
confirmed: 0
needs_review: 0
not_actionable: 19
```

Alert `#2` is a public-metadata misclassification. Alerts `#3`–`#17` do not cross
a supported external-attacker boundary in the current local CLI product model.
Alerts `#1`, `#18`, and `#19` are non-security correctness or maintainability
results. All GitHub alerts remain open; no dismissal or state update was
performed.

### COMM-VER-01 Closeout

```text
repository reference: a6b7b634214ea4db55efb7a69cd2e663ea052d61
OpenSSL inventory/run: 124/124 PASS
external inventory/run: 124/124 PASS
inventory names/order: identical
external-backend-parity-check: PASS
backend-boundary-check: PASS
external-backend-hook-check: PASS
```

CTest inventory JSON, JUnit XML, toolchain data, command logs, and hashes were
retained. The executed source was reconstructed from a known uploaded baseline and
exact implementation/CMake deltas because a current clone was unavailable. The
unchanged tests used a temporary external GoogleTest API compatibility runner
because the declared GoogleTest v1.14.0 dependency was also unavailable. This
closes local provider behavior and inventory parity only with those execution
caveats.

### COMM-VER-02 Closeout

```text
COMM-VER-02: COMPLETE LOCAL EXACT
source checkout: exact 1d933eb detached Git worktree
GoogleTest v1.14.0 official source: verified and executed
OpenSSL: 124/124 PASS
external: 124/124 PASS
inventory: identical
backend-boundary-check: PASS
external-backend-hook-check: PASS
external-backend-parity-check: PASS
COMM-VER-01 harness/source caveats: superseded
hosted confirmation: DEFERRED_EXTERNAL_BILLING
evidence SHA-256: d3ae3dfb3d06bd071f6692fe89272ed759f01f55280096c84e13e34f77afa978
```

COMM-VER-01 remains historical evidence. COMM-VER-02 supersedes only its current
harness and source-provenance caveats.

### COMM-REL-03 Closeout

```text
publication evidence archive: PASS SELF-CONTAINED
asset inventory/integrity/SBOM: PASS
online asset attestations: PASS 20/20
offline retained-bundle verification: PASS 20/20
release body exact comparison: NOT_EQUAL
hosted current-main reruns: DEFERRED_EXTERNAL_BILLING
evidence archive: COMM-REL-03-v0_4_0-self-contained-evidence.zip
evidence SHA-256: e556263cb971811b980c242e20524c8b42db362dfd0ef1d07ff3633a1868d93c
```

The archive retains all 20 assets, strict online outputs, bundles, trusted root,
strict offline outputs, exact-commit Actions and CodeQL metadata, raw comparison
inputs, unified diff, and internal hashes. COMM-REL-02 remains historical.

### COMM-DOC-02 Closeout

- GitHub Pages landing, roadmap, security, license, and release-verification
  wording aligns with the canonical repository boundaries;
- README points to `docs/NEXT_WORK_QUEUE.md` as the only active queue;
- `docs/ROADMAP.md` is a compatibility entry point only;
- candidate-era `v0.4.0` preparation wording and `default backend` wording were
  removed from current surfaces;
- Enterprise and AnoCrypto-C naming is consistent;
- `document-alignment-check` prevents recurrence and runs in release preflight;
- no production code, public API, CLI, CMake identity, fixture, provider
  selection, or v1 format meaning changed.

### COMM-REL-04A Closeout

The v0.4.1 maintenance source was prepared and committed at repository reference
`ba710b3f618db0b21664dde892e1f048c43218a4`. The project version is `0.4.1`, the
canonical release-note section is supplied through `--notes-file`, and the full
local release-preflight passed before the later CLI-output hardening review.

### COMM-PROD-01 Closeout

The product audit organized the existing product into three supported flows:

```text
Secure Bytes
Secure Files
Secure Keys
```

The audit confirmed that product work remains beyond release operations. It
identified CLI output creation as a v0.4.1 blocker and retained public
verification APIs, shared-library symbol control, safer secret input, failure
injection, product documentation, and distribution as later work.

### COMM-HARD-02 Closeout

The CLI previously created generic file outputs through `std::ofstream`; under a
POSIX `umask 022`, generated keys and recovered plaintext were observed as mode
`0644`. The private CLI output helper now:

- creates random temporary output with an operating-system exclusive open;
- requests owner read/write mode `0600` on POSIX;
- preserves existing-destination rejection and commit-after-success behavior;
- removes temporary output after failure;
- covers key generation, wrap/unwrap, packet encrypt/decrypt, and stdin-to-file
  seal/open paths with focused permission regression tests.

The public C++ API, CLI syntax, CMake identity, OpenSSL provider, and v1 formats
remain unchanged. Full local release-preflight and identical 124-test OpenSSL and
external-provider inventories passed for the prepared patch. Resolve the exact
current revision from Git after the change is committed.

## COMM-REL-04B — Hosted Validation And Publish v0.4.1

Priority: P1
Status: `BLOCKED_EXTERNAL_BILLING`

After billing recovery, verify the final source tree, rerun local release
preflight, trigger main CI and CodeQL, manually dispatch Fuzz, and require all
hosted Linux, sanitizer, Windows, macOS, package, CodeQL, and Fuzz lanes to pass
for the exact final commit. Only then create and push `v0.4.1`, verify the Release
body against `docs/RELEASE_NOTES.md`, assets, checksums, SPDX SBOM, and
attestations, and close the release. Hosted results remain
`DEFERRED_EXTERNAL_BILLING` until that execution occurs.

## COMM-CODEQL-03 — Apply GitHub Alert Dispositions

Priority: OPTIONAL / REQUIRES EXPLICIT AUTHORIZATION

Only after reviewing the rule-level triage table, optionally update GitHub alert
states with one reason and comment per alert. Do not bulk-dismiss solely from
severity labels or the aggregate `not_actionable` count. Keeping the alerts open
is acceptable.

## COMM-PLAT-01 — Refresh Hosted Platform Matrix

Priority: P2 / DEFERRED_EXTERNAL while billing is blocked

The v0.4.0 Windows/macOS lanes are verified. Re-run current hosted lanes only when
runner billing is restored or platform requirements change.

## COMM-SEC-02 — Conduct Focused External Security Review

Priority: OPTIONAL / EXTERNAL
Status: READY, NOT_STARTED

Use the completed COMM-SEC-01 readiness package if an independent reviewer is
engaged. The package is an intake artifact and does not constitute a completed
security audit.

## COMM-DX-01 — Public File Verification APIs

Priority: P1 / TARGET v0.5.0

Design named raw-key and password file-verification APIs that authenticate
without creating plaintext output. Preserve `SKF1` and `SKP1` compatibility and
complete public API review before implementation.

### COMM-ABI-01 Closeout — Shared Library Symbol Allowlist

Status: COMPLETE LOCAL FEATURE CANDIDATE / TARGET v0.5.0

Shared builds now hide symbols by default and export only the reviewed public
ABI. The measured ELF dynamic surface fell from 137 entries to 59 entries, or 52
unique demangled public symbols after constructor/destructor normalization.
Internal provider, parser, file-I/O, and secure-wipe symbols are hidden.

`shared-symbol-annotation-check`, binary `shared-symbol-check`, and clean installed
`shared-package-check` gates were added. `anosecurekit::error` is class-exported
to preserve cross-DSO exception RTTI. This work remains isolated with COMM-DX-01
on the v0.5.0 development line and must not enter v0.4.1.

## COMM-DX-02 — Safe CLI Binary And Secret Input Contract

Priority: P1 / TARGET v0.5.0

Review byte-exact stdout behavior, safer HMAC/HKDF key sources, packet-size
intent, and compatibility migration without changing existing v1 meanings.

## COMM-TEST-01 — Failure Injection And Concurrency

Priority: P1

Add deterministic backend/filesystem failure coverage and document independent-
context thread-safety behavior.

## COMM-DOC-03 — Three-Pillar Product Experience

Priority: P1

Reorganize first-contact README, site, and examples around Secure Bytes, Secure
Files, and Secure Keys while retaining detailed reference material.

## COMM-DIST-01 — Adoption Channels

Priority: P2

After the v0.5 public API direction stabilizes, validate and publish selected
package-manager recipes with retained consumer evidence.

## Version Direction

- Keep `v0.4.0` as the published release baseline.
- Do not move or recreate `v0.4.0`.
- Use `v0.4.1` when the fuzz fix and maintenance changes are published.
- Use `v0.5.0` only for intentional public product evolution.
- Do not reinterpret `SKT1`, `SKF1`, or `SKP1` v1.
