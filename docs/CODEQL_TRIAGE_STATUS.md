<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community CodeQL Triage Status

Status: CURRENT
Triage date: 2026-07-17 (Asia/Seoul)
Repository baseline: `a72aa8e96de6e9e312f13aabbb8baa1a17c36a4b`
Analysis target: `694459ebe497d15ba75ef76a52fa7c36ddd7bcce`

## Evidence Identity

```text
collection state: COLLECTION_COMPLETE
analysis IDs: 1471089159, 1471719182
results per analysis: 19
unique GitHub alerts: 19
SARIF relation: byte-identical
alert state: open, 19/19
alert severity: warning, 19/19
security severity: high 16, none 3
evidence archive: COMM-CODEQL-01-evidence.zip
archive SHA-256: f899b0036fe0f2d07f7923d23b2932844c5b57b60ed00c65b383dd6f610b28d8
```

The two analysis result sets are duplicate executions of the same SARIF content.
They represent 19 unique alerts, not 38 distinct findings.

## Triage Result

```text
confirmed: 0
needs_review: 0
not_actionable: 19
active Community security findings from this collection: 0
```

### Alert groups

| Alerts | Verdict | Rationale |
| --- | --- | --- |
| `#2` | `not_actionable` | Public SKP1 header metadata was classified as sensitive plaintext. The cited metadata is intentionally public format information, not a secret or plaintext payload. |
| `#3`–`#17` | `not_actionable` | The paths are explicitly supplied by a local CLI operator. Static review did not establish a supported lower-privileged or remote attacker source crossing an AnoSecureKit security boundary. Re-triage if the CLI is later embedded in a service, multi-user broker, or other boundary-changing product surface. |
| `#1`, `#18`, `#19` | `not_actionable` for security | These are correctness or maintainability results without a demonstrated confidentiality, integrity, authentication, authorization, memory-safety, or unsafe-output consequence. They may be retained as ordinary quality backlog items. |

`not_actionable` is the static Community security-triage verdict. It does not mean
the GitHub alerts were dismissed, fixed, or deleted.

## Alert State

All 19 GitHub alerts remained `open` after triage. No alert dismissal, state
update, workflow change, source modification, staging, commit, or push was
performed by COMM-CODEQL-01 or COMM-CODEQL-02.

Any future GitHub disposition action requires explicit authorization and should
retain the rule, location, alert number, reason, and explanatory comment. Do not
bulk-dismiss alerts solely because their current security verdict is
`not_actionable`.

## Security Boundary

The triage used the Community security policy and current shipped product model:

- local CLI path choices are not automatically attacker-controlled;
- public serialized-format metadata is not secret merely because it precedes
  encrypted content;
- a CodeQL `warning` or `high` rule label does not establish exploitability;
- a supported actor, source, reachable sink, crossed boundary, and security
  consequence are all required before promoting an alert to `confirmed`.

This conclusion must be revisited if the affected paths become remotely
controlled, cross privilege boundaries, or are used by a hosted or multi-tenant
surface.

## Claims Boundary

This is static alert triage, not an external security audit or certification.
AnoSecureKit Community makes no FIPS, KCMVP, validation, certification, or
public-sector approval claim.
