<!-- SPDX-License-Identifier: MPL-2.0 -->
# Public file verification API

Status: Phase 4 additive implementation; unreleased, no version/tag changes.

`verify_file(input, key, aad={})` authenticates SKF1.
`verify_file_with_password(input, password, aad={})` authenticates SKP1.
Both accept a filesystem path or `std::istream&` and return `void` on success.
No plaintext output path or output stream is accepted. They read through the
final authenticated record and reject trailing bytes. A stream is consumed from
its current position; it is not rewound, closed or restored on failure.

The implementation reuses the existing stream open functions with a private
non-buffering discard stream. It decrypts bounded chunks in process memory and
retains the existing scoped cleanup of derived keys and chunk plaintext. There
is no new crypto operation, output file, plaintext callback, KDF setting or wire
format. Guaranteed erasure, swap/crash-dump protection and protection against a
malicious caller-provided input stream are not promised.

Errors match the existing open functions: malformed/unsupported input is
`invalid_packet`, authentication failure is `authentication_failed` with the
generic `File authentication failed` message, and file read/open failures use
`backend_failure`. Password bytes are exact; an empty password is `invalid_input`
before opening/reading input. As with existing stream APIs, caller-enabled stream
exceptions can propagate. Success describes the bytes consumed during this call;
it does not prevent subsequent modification or replacement of an input path.

Existing open/seal APIs, CLI verification behavior, package identities and
OpenSSL provider context remain unchanged. Shared ABI integration is reviewed in
a separate dependent PR; this addition alone does not establish an ABI guarantee.
