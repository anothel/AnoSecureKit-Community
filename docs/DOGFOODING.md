<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Dogfooding

Dogfooding checks one release-like package as a user would consume it, without
adding new public surface.

Run:

```sh
cmake --build build --config Release --target dogfood-check
```

The check:

- extracts one binary archive from `package-check` artifacts;
- runs `keygen`, `seal-file`, `verify-file`, and `open-file`;
- runs the password file flow with `seal-file-password`,
  `verify-file-password`, and `open-file-password`;
- configures, builds, and runs a copied C++ consumer from the extracted
  package's installed CMake config.

## v0.2.0 local dogfood

Result: no repeated friction recorded.

This run did not require extra public surface. Any reproducible follow-up belongs
in the canonical `docs/NEXT_WORK_QUEUE.md` with a named check and rollback path.
