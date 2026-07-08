<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Web Roadmap

This document tracks only work for the AnoSecureKit GitHub Pages site.
C++ API, CLI, package, and release work belong in `docs/ROADMAP.md`.

Completed work belongs in Git history and, when release-facing, in
`docs/RELEASE_NOTES.md`.

## Scope

The site should:

1. Explain what AnoSecureKit is quickly.
2. Link users to the repository, docs, and release verification.
3. State security boundaries and unsafe use clearly.
4. Provide small browser-local tools without uploading user input.

## Current Plan

### Now

None.

The site landing page, CLI page, security page, Base64/Base64URL guides,
SHA-256 guide and tool, random token guide and tool, HMAC-SHA-256 guide and
tool, AES-GCM guide and text demo are complete enough to stay out of active
roadmap work.

### Deferred

File sealing browser tool:

- status: deferred
- reason: file, key, password, protected output, and failure-handling UX is too
  risky for the current browser-tool scope
- revisit only if: separate security UX, failure-output handling, browser API
  limits, and test vectors are designed first
- rollback: keep users on the CLI and C++ API docs

AnoSecureKit packet format viewer:

- status: deferred
- scope: read-only packet structure explanation or sample fixture inspection
- blocked by: no concrete user problem or safe input handling design yet
- check: fixture-based browser self-test and no mobile overflow
- rollback: remove viewer links and keep guide docs only

Advertising:

- status: deferred
- allowed area: guide or general docs page footer
- forbidden area: browser-local tool pages, key/password/file input areas,
  action buttons, and download buttons
- requires approval: ad network, third-party script, and placement

Analytics:

- status: deferred
- allowed source: GitHub Pages and GitHub repository statistics
- forbidden data: user input, output, key, nonce, AAD, filename, tool errors,
  and per-user tracking
- forbidden methods: cookies, fingerprinting, and session re-identification
- requires approval: any separate analytics service, third-party script, or
  retention period

## Rules

- Tool pages must stay browser-local.
- Do not add third-party scripts to tool pages.
- Do not upload plaintext, keys, passwords, files, output, or tool errors.
- Prefer static HTML, CSS, and JavaScript over a web framework.
- Prefer relative links such as `./guides/base64.html` for GitHub Pages project
  paths.
- Do not add ads, analytics, custom domains, server APIs, login, or paid
  services without explicit approval.
- Do not add WebAssembly unless a concrete user problem needs
  AnoSecureKit-compatible binary formats in-browser.

## Checks For Future Web Changes

Run the smallest relevant checks for the changed surface:

```sh
git diff --check
cmake --build build --config Release --target check
cmake --build build --config Release --target format-check
```

For browser-local tools, also verify:

- known vector or self-test passes
- encrypt/decrypt or encode/decode round trip works where applicable
- no horizontal overflow at 390, 768, and 1024 px widths
- page text states local-only processing and relevant security limits

## Not Doing

- File upload encryption service
- Browser file sealing demo
- Password-based browser encryption
- Server-side crypto API
- Login or account features
- Docusaurus, Astro, Next.js, or separate site repository
- Advertising or analytics on tool pages
- Custom domain purchase
