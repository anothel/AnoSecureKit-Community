<!-- SPDX-License-Identifier: MPL-2.0 -->

# Public File Verification API

Status: REVIEWED IMPLEMENTATION CANDIDATE
Target: v0.5.0
Base revision: `df1936777843415022a97f775c6e61eea6d99cb0`

Add `verify_file` and `verify_file_with_password`, each with path and stream overloads. Successful return means the complete input authenticated. Failures retain the matching open API's `anosecurekit::error_code` contract.

## Security Invariants

- No plaintext output path or output stream is accepted.
- Decrypted chunks remain inside AnoSecureKit and are wiped after use.
- Final-record and trailing-data checks are unchanged.
- Wrong key, password, AAD, ciphertext, nonce, or tag remains a generic authentication failure.
- Malformed input remains `invalid_packet`; I/O failures remain `backend_failure`.
- Password bytes remain exact and empty passwords remain invalid.
- `SKF1`, `SKP1`, provider behavior, and AAD rules do not change.

A boolean result and a verifier object were rejected because they would either collapse errors or add lifecycle without caller-visible state. The existing throwing free-function model is the smallest compatible API. The CLI commands call these APIs directly.

Do not merge this feature into the v0.4.1 maintenance release line. Rebase it onto the final v0.4.1 release revision, move the development version to v0.5.0, and rerun all local and hosted gates before publication.
