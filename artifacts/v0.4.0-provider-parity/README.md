<!-- SPDX-License-Identifier: MPL-2.0 -->

# COMM-VER-01 Provider Parity Evidence

Repository reference: `a6b7b634214ea4db55efb7a69cd2e663ea052d61`

```text
OpenSSL: 124/124 PASS
external: 124/124 PASS
inventory: identical
```

External evidence archive:

```text
COMM-VER-01-evidence.zip
SHA-256: 5dc4e449ee0a57ba7a53ab256d2196c4e10ba076ff125e5cdff90fe7af63091b
```

The archive records an implementation-equivalent source reconstruction and uses a
temporary GoogleTest API compatibility runner because the collection environment
could not clone the current repository or obtain upstream GoogleTest v1.14.0. See
`docs/PROVIDER_PARITY_STATUS.md`. Full logs and binaries remain outside source
control.
