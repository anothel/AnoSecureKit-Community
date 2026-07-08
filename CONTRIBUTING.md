<!-- SPDX-License-Identifier: MPL-2.0 -->

# Contributing

Use the release preflight before calling a change ready:

```sh
cmake -S . -B build -DANOSECUREKIT_BUILD_TESTS=ON
cmake --build build --config Release --target release-preflight
```

## One-command local check

After the build directory exists, this is the local release gate:

```sh
cmake --build build --config Release --target release-preflight
```

`release-preflight` requires `ANOSECUREKIT_BUILD_TESTS=ON`,
`ANOSECUREKIT_BUILD_CLI=ON`, and `ANOSECUREKIT_INSTALL_CLI=ON`.

Do not add public API, wire formats, package channels, CI cost, or release
ceremony without a written problem, regression check, and rollback plan.

Do not expand AnoSecureKit into TLS, networking, web middleware, custom crypto,
secure key storage, or framework-scale abstractions.

Do not contribute AnoCrypto implementation code, AnoCrypto scaffolds, Enterprise
license logic, or certification/approval claims to this Community repository.

## License And File Headers

Contributions to AnoSecureKit are accepted under `MPL-2.0`. By contributing,
you agree that your contribution can be distributed under the repository license.

New source files should include a machine-readable SPDX identifier:

```cpp
// SPDX-License-Identifier: MPL-2.0
```

For non-C++ files, use the comment syntax appropriate for the file type.

## Documentation Changes

Update documentation in the same change when behavior changes. In particular:

- public API changes must update `README.md` and `docs/PUBLIC_API_POLICY.md` if
  the policy changes;
- CLI changes must update `docs/CLI.md`, website CLI summaries, and CLI tests;
- serialized format changes must update `docs/FORMAT.md` and fixtures;
- security-boundary changes must update `docs/SECURITY_MODEL.md` and
  `docs/OPENSSL_POLICY.md` when applicable;
- license or package metadata changes must update `LICENSE`,
  `docs/LICENSE_POLICY.md`, release/package checks, and generated recipe rules.

Do not keep completed implementation plans in public `docs/`. Use release notes
for completed user-visible changes and Git history for detailed implementation
history.
