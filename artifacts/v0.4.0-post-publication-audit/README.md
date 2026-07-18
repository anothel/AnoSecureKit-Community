<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community v0.4.0 Publication Evidence

Status: PASS SELF-CONTAINED

```text
release tag: v0.4.0
release commit: 694459ebe497d15ba75ef76a52fa7c36ddd7bcce
published: 2026-07-13 19:26:47 KST
publication evidence archive: PASS SELF-CONTAINED
asset inventory/integrity/SBOM: PASS
online asset attestations: PASS 20/20
offline retained-bundle verification: PASS 20/20
release body exact comparison: NOT_EQUAL
hosted current-main reruns: DEFERRED_EXTERNAL_BILLING
release assets: 20/20
SHA256SUMS: PASS 19/19
SPDX SBOM: PASS 18/18
GitHub asset digests: PASS 20/20
hosted tag CI: PASS, 10/10 jobs
Windows: PASS, 4/4
macOS: PASS, 2/2
```

External evidence archive identity:

```text
file: COMM-REL-03-v0_4_0-self-contained-evidence.zip
SHA-256: e556263cb971811b980c242e20524c8b42db362dfd0ef1d07ff3633a1868d93c
```

The full evidence archive and release binaries are not committed to the source
repository. The published release assets remain the authoritative binary source.
The normalized Release body is `NOT_EQUAL`: `shipped` became `official`, and
`provider` became `provider or adapter`. The release workflow used
`gh release create --generate-notes`; the retained diff records the result.

Historical archive identity retained:

```text
file: COMM-REL-02-v0_4_0-evidence.zip
SHA-256: 76782f2d8840a183fc91cae0b6268e33d8f77e38f05c2b5dd9e426bb176ca356
```
