<!-- SPDX-License-Identifier: MPL-2.0 -->

# Security Policy

## Reporting A Vulnerability

Do not report security vulnerabilities through public GitHub issues.

Preferred path: open a private report through GitHub Security Advisories:
<https://github.com/anothel/AnoSecureKit-Community/security/advisories/new>.

If that path is unavailable, use a private contact method listed on the
maintainer GitHub profile: <https://github.com/anothel>. Do not publish details
until a fixed release or advisory is ready.

Include enough information to reproduce and classify the issue:

- AnoSecureKit version, tag, or commit
- OS, compiler, CMake, and OpenSSL versions
- OpenSSL provider configuration if relevant
- minimal reproducer
- expected behavior
- actual behavior
- affected API, CLI command, or serialized format
- whether plaintext, keys, passwords, or authenticated data may be exposed
- exploitability assumptions

## Supported Versions

Community maintenance resumed on 2026-11-15 under docs/REVIVAL_PLAN.md;
PRs #1–#5 are merged. This does not establish a supported-version policy or
response SLA. Release publication, future scope and risk acceptance still require
an explicit maintainer decision. See docs/REVIVAL_PHASE6_RESULTS.md for remaining
evidence gaps; no external security audit has occurred.

Published v0.4.0 generic CLI output can create key or plaintext files with mode
`0644` under a POSIX `umask 022`. Unpublished main retains the maintenance fix using exclusive temporary-file
creation and mode `0600`. That fix is not in the published v0.4.0 Release;
source 0.4.1 is unpublished; the next release version is not selected.

## Disclosure

Reports may be retained for archival triage, but submission does not promise a
response, fix, advisory, or release. If security work is explicitly reopened,
disclosure timing will be coordinated before exploit details are published.

## Scope

In scope:

- authentication bypass
- plaintext exposure caused by AnoSecureKit
- key, nonce, or AAD misuse caused by AnoSecureKit
- unsafe output-file behavior
- parser crashes or memory safety issues caused by malformed AnoSecureKit packets
  or files
- misleading security documentation that could cause unsafe use

Out of scope:

- vulnerabilities in caller code
- insecure storage or transmission of caller-provided keys or passwords
- compromised operating systems, filesystems, shells, or build hosts
- unsupported OpenSSL versions
- misuse of APIs after documented preconditions are ignored

## Security Claims

AnoSecureKit Community uses OpenSSL 3.x as its only shipped production provider.
Its external provider seam is build-tree-only. Community does not include
Enterprise proprietary code or an AnoCrypto-C adapter and makes no KCMVP, FIPS,
certification, validation, security-audit, or public-sector approval claim.

## Security Release Notes

If release work is explicitly reopened, security-impacting releases should
mention the affected surface, fixed version, upgrade instructions, and whether
existing `SKT1`, `SKF1`, or `SKP1` data needs to be regenerated.
