<!-- SPDX-License-Identifier: MPL-2.0 -->

# Community Split Notes

This repository was extracted from the uploaded AnoSecureKit codebase as the
public AnoSecureKit Community edition.

The extraction intentionally keeps the existing public package surface:

- `anosecurekit` package and CLI name.
- `include/anosecurekit` public include root.
- `anosecurekit` C++ namespace.
- `anosecurekit::anosecurekit` CMake target.
- `SKT1`, `SKF1`, and `SKP1` v1 serialized formats.

The extraction intentionally removes generated build directories and local IDE
state from the distributed source archive.

Enterprise and AnoCrypto work should happen in separate private/commercial
repositories.
