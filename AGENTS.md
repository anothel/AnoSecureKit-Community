<!-- SPDX-License-Identifier: MPL-2.0 -->
# Repository rules

- Work on a dedicated branch from the reviewed baseline; never edit main directly.
- Preserve the public C++ API, package/target names and SKT1/SKF1/SKP1 v1 bytes,
  fixtures, scrypt parameters and `anosecurekit file sealing v1` HKDF label.
- Community ships OpenSSL Crypto 3.x only. Respect the caller's provider context;
  external providers are build-tree-only, with no silent fallback or Enterprise code.
- Authenticate before committing path output. Use exclusive private temporary files,
  POSIX 0600 (subject to a more restrictive umask), and atomic no-overwrite commit.
  Stream/stdout output cannot be rolled back; never promise otherwise.
- Keep errors generic and secret-free. Do not promise secure erasure, external audit,
  certification, FIPS or KCMVP status without evidence.
- Add regression tests for confirmed defects before fixes; retain working hardening.
  Run CMake `check`, `format-check`, `package-check`, `external-backend-parity-check`
  and relevant document/boundary checks. Record commands, environment, actual results
  and skipped checks. POSIX builds with CLI tests require Python 3.7+ for the security matrix;
  CI/review must run it, not silently treat its absence as a pass.
- Keep changes and PRs independently reviewable. Do not merge, release, move existing
  tags, or dismiss alerts automatically. Historical closeout evidence is not current
  verification. See docs/REVIVAL_PLAN.md for resumed scope.

## Codex result handoff

- Check the existing task/issue, its latest authorized scope, the exact base revision, and open PRs before starting or resuming. Do not duplicate active work or silently change an approved baseline.
- Use an isolated task branch/worktree. Follow this repository's existing contribution, test, review, security, and authorization rules; this section grants no additional implementation, Git-write, merge, deployment, or release permission.
- For an authorized task, record the outcome on its existing GitHub issue or PR (including blocked and read-only work). Include task ID, status, base/head SHA, changed files/commits or none, actual test results with PASS/FAIL/BLOCKED/NOT_RUN, CI and Draft PR links if applicable, remaining risks, and the next action. If Jira is in use, link its existing task instead of duplicating the full report.
- Publish only sanitized evidence through an authorized channel. Do not publish credentials, customer data, private paths, or sensitive vulnerability details in public issues or PRs. Use an approved private channel for sensitive evidence.
- If GitHub write access is unavailable or publication is not authorized, report the exact blocker and the minimum safe handoff. Do not bypass access controls, fabricate evidence, or treat a successful workflow as human approval.
- The project manager verifies GitHub evidence and updates project tracking. No agent may impersonate an independent human reviewer or bypass existing merge/release gates.
