<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community

Project site: https://anothel.github.io/anosecurekit-community/

AnoSecureKit Community is the open-source edition of the AnoSecureKit product family.
It is licensed under MPL-2.0 and uses OpenSSL 3.x as its default production
cryptographic backend. The package name, include root, C++
namespace, CLI, and CMake target intentionally remain `anosecurekit`.

AnoSecureKit Enterprise is separate commercial software. AnoCrypto is an
external proprietary cryptographic module managed outside this repository.
AnoCrypto is not included in Community, and Community does not provide an
AnoCrypto backend.

AnoSecureKit Community makes no KCMVP, FIPS, certification, validation, or
public-sector approval claims.

AnoSecureKit does not aim to invent new cryptographic algorithms. Native
cryptographic work, when used, must implement established algorithms behind
provider boundaries and be protected by known-answer tests, differential tests,
fuzzing, compatibility fixtures, and review.

Security status: AnoSecureKit has not had an external security audit. It is a
small utility library with OpenSSL as the current default backend, compatibility
fixtures, CI, fuzz smoke targets, package checks, release checksums, an SPDX
SBOM, and GitHub artifact attestations. Do not treat it as a substitute for a
full security review in high-risk systems.

## License

AnoSecureKit is licensed under the Mozilla Public License 2.0 (`MPL-2.0`).
Commercial and closed-source use is allowed. If AnoSecureKit source files are
modified and the modified version is distributed, the modified AnoSecureKit files
must remain available under `MPL-2.0`. This does not require unrelated
application code that merely uses AnoSecureKit as a separate library to be
opened because of AnoSecureKit alone.

See [`docs/LICENSE_POLICY.md`](docs/LICENSE_POLICY.md) for the project-level
license explanation. The full license text is in [`LICENSE`](LICENSE).

## What This Project Is

AnoSecureKit is for application code that needs common binary and crypto helpers
without pulling low-level provider calls through the whole codebase.

The current identity is:

- Practical C++20 security utility library.
- OpenSSL 3.x backed by default.
- Backend-neutral public API, CLI, and file formats.
- No AnoCrypto source, scaffold, or backend.
- No novel or unpublished cryptographic algorithms.
- Free-function API first.
- Distinct packet streaming objects where incremental AEAD is useful.

## Backend Strategy

AnoSecureKit Community uses OpenSSL 3.x as the default production backend.
AnoCrypto is an external proprietary module and is not part of this repository.

The Community backend boundary is:

1. Keep AnoSecureKit's public API, CLI, and `SKT1` / `SKF1` / `SKP1` formats stable.
2. Keep OpenSSL 3.x as the only public production backend.
3. Keep AnoCrypto source, scaffolding, and integration code outside Community.
4. Keep Enterprise license, activation, packaging, and support logic outside Community.

## Features

- Hex encode and decode.
- Base64 encode and decode.
- Base64URL encode and decode.
- SHA-256 digest.
- HMAC-SHA-256 digest.
- HKDF-SHA-256 key derivation.
- Constant-time byte comparison for equal-length secret values.
- Cryptographically secure random bytes.
- URL-safe random token generation.
- AES-256-GCM packet encryption and decryption.
- Move-only packet streaming encryptor and decryptor for `SKT1`.
- AES-256-GCM key wrapping helpers.
- Chunked file sealing and opening with path and stream APIs.
- Password-based chunked file sealing and opening with `SKP1` and scrypt.

## Which API Should I Use?

| Goal | Prefer | Why |
| --- | --- | --- |
| Encrypt a small message | `anosecurekit::encrypt` / `anosecurekit::decrypt` | Plaintext is returned only after authentication succeeds. |
| Seal a file with a raw key | Path-based `anosecurekit::seal_file` / `anosecurekit::open_file` | Open refuses existing outputs, writes a temporary file, and commits only after authentication succeeds. |
| Seal a file with a password | Path-based `anosecurekit::seal_file_with_password` / `anosecurekit::open_file_with_password` | Uses the fixed `SKP1` scrypt profile and the same path-output safety behavior. |
| Verify an encrypted file before restore | `anosecurekit verify-file` / `anosecurekit verify-file-password` | Authenticates without creating a plaintext output file. |
| Process an `SKT1` packet incrementally | `anosecurekit::packet_encryptor` / `anosecurekit::packet_decryptor` | Advanced use only; decrypted chunks are unverified until `finalize()` succeeds. |
| Stream file data through caller-owned streams | Stream overloads or CLI `--out -` | Advanced use only; caller must discard output if the operation fails. |

## Non-goals

- TLS or networking. Use TLS libraries for that.
- Generic password hashing or general-purpose password KDF APIs.
- Generic streaming object families beyond the `SKT1` packet slice.
- Custom string classes or allocators.
- User-selected algorithms or caller-selected nonces.
- Text encoding or string-to-byte conversion helpers.
- Secure key storage.
- Guaranteed key erasure.
- Novel, unpublished, or project-specific cryptographic algorithms.
- Promoting unaudited native cryptographic implementations as the default backend.

## Release Surface Contract

Public claims are limited to the C++ APIs listed in Public API, CLI commands
listed in [docs/CLI.md](docs/CLI.md), the `SKT1`, `SKF1`, and `SKP1` formats,
and packaged CMake surfaces described here. `release-preflight` checks these
docs against public headers, CLI command usage, install/export/package
artifacts, release assets, and provenance files before release.

External audits and roadmap notes are handled through this contract. Items that
do not map to the C++ API, CLI, `SKT1`/`SKF1`/`SKP1`, CMake package, release
asset, or security-reporting surface are triage input, not implementation scope.
`docs/ROADMAP.md` records the active work queue.

For the canonical documentation map, see
[`docs/DOCUMENTATION_GUIDE.md`](docs/DOCUMENTATION_GUIDE.md).

For product-edition boundaries, see [`docs/EDITIONS.md`](docs/EDITIONS.md) and
[`docs/ANOCRYPTO_BOUNDARY.md`](docs/ANOCRYPTO_BOUNDARY.md). The approved
internal provider-seam direction is documented in
[`docs/BACKEND_ARCHITECTURE.md`](docs/BACKEND_ARCHITECTURE.md).

## Requirements

- C++20 compiler.
- CMake 3.20 or newer.
- OpenSSL 3.x, version 3.0 or newer, when using the current default OpenSSL backend.
- No AnoCrypto source, scaffold, or backend is shipped in Community.

## Build

Contributor workflow: see [CONTRIBUTING.md](CONTRIBUTING.md) for the
one-command local release check.

Generic CMake:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DANOSECUREKIT_BUILD_TESTS=ON
cmake --build build --config Release --target check
cmake --build build --config Release --target format-check
cmake --build build --config Release --target package-check
cmake --build build --config Release --target spdx-check
cmake --build build --config Release --target legacy-name-check
cmake --build build --config Release --target cli-docs-check
```

`format-check` requires `clang-format` on `PATH` and checks the repository's
C++ sources against `.clang-format`. `spdx-check` verifies MPL-2.0 SPDX headers,
`legacy-name-check` rejects stale old-name or Apache-era identifiers outside
allowlisted release-note context, and `cli-docs-check` compares the built CLI's
`--help` output with `docs/CLI.md`.
For coverage, configure a separate GCC/Clang build with
`-DANOSECUREKIT_ENABLE_COVERAGE=ON`, then run `coverage-report`.

Windows with vcpkg:

```powershell
cmake -S . -B build-vcpkg `
  -DANOSECUREKIT_BUILD_TESTS=ON `
  -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" `
  -DVCPKG_TARGET_TRIPLET=x64-windows

cmake --build build-vcpkg --config Release --target check
cmake --build build-vcpkg --config Release --target package-check
cmake --build build-vcpkg --config Release --target release-workflow-check
cmake --build build-vcpkg --config Release --target release-preflight
```

`package-check` installs AnoSecureKit, runs the installed CLI, verifies a consumer
CMake project against the installed package, builds CPack binary and source
archives, checks key files inside those archives, extracts one source archive,
and verifies that the extracted source can configure, build, install, and run
`anosecurekit --version`. Generated archives are written under
`<build>/package-check/artifacts`.
`release-preflight` runs the local release targets, stages release assets under
`<build>/package-check/release-assets`, writes `SHA256SUMS.txt`, and then checks
SemVer, README/release-checklist version examples, documented local targets,
package artifact version prefixes, staged release asset checksums, and release
provenance attestation wiring. It also writes Homebrew, Conan, and vcpkg recipe
drafts under `<build>/package-check/package-recipes` using the staged source
archive URL and checksum.

## CMake Options

| Option | Default | Use |
| --- | --- | --- |
| `ANOSECUREKIT_BUILD_TESTS` | `BUILD_TESTING` | Build unit, fixture, and CLI tests. |
| `ANOSECUREKIT_BUILD_CLI` | `ON` | Build the `anosecurekit` CLI executable. |
| `ANOSECUREKIT_INSTALL_CLI` | `ON` | Install the CLI. Requires `ANOSECUREKIT_BUILD_CLI=ON`. |
| `ANOSECUREKIT_BUILD_FUZZ` | `OFF` | Build optional libFuzzer smoke targets. See [docs/FUZZING.md](docs/FUZZING.md). |
| `ANOSECUREKIT_ENABLE_COVERAGE` | `OFF` | Add GCC/Clang coverage instrumentation for the non-blocking `coverage-report` target. See [docs/COVERAGE.md](docs/COVERAGE.md). |
| `ANOSECUREKIT_WARNINGS_AS_ERRORS` | `OFF` | Treat AnoSecureKit compiler warnings as errors. |
| `ANOSECUREKIT_CRYPTO_BACKEND` | `openssl` | Select `openssl` for the shipped Community provider or `external` for the internal build-tree integration hook. |
| `ANOSECUREKIT_EXTERNAL_BACKEND_TARGET` | empty | Existing non-imported `OBJECT_LIBRARY` provider target required by the build-tree-only `external` mode. |

The shipped Community profile is `ANOSECUREKIT_CRYPTO_BACKEND=openssl`. The
`external` value is an internal build-tree hook for a parent project that defines
an `OBJECT_LIBRARY` provider target before adding AnoSecureKit with
`add_subdirectory()`. It is not installed, packaged, or supported as a Community
provider, and a missing or invalid target fails configuration. Run
`external-backend-hook-check` to verify the positive and fail-closed paths.

Release package check targets `package-check` and `release-preflight`
require the OpenSSL profile plus `ANOSECUREKIT_BUILD_CLI=ON` and
`ANOSECUREKIT_INSTALL_CLI=ON` because they install and run the CLI. Library-only
consumers can disable tests and the CLI:

```sh
cmake -S . -B build-lib-only \
  -DANOSECUREKIT_BUILD_TESTS=OFF \
  -DANOSECUREKIT_BUILD_CLI=OFF \
  -DANOSECUREKIT_INSTALL_CLI=OFF
```

If tests cannot find OpenSSL DLLs on Windows, pass:

```powershell
-DANOSECUREKIT_OPENSSL_RUNTIME_DIR="path\to\vcpkg\installed\x64-windows\bin"
```

If you are not using a vcpkg toolchain file, point CMake at an OpenSSL prefix:

```powershell
cmake -S . -B build-openssl `
  -DANOSECUREKIT_BUILD_TESTS=ON `
  -DOPENSSL_ROOT_DIR="path\to\openssl-prefix"
```

## Test Dependency

When `ANOSECUREKIT_BUILD_TESTS=ON`, CMake first looks for an installed `GTest`
package. If none is found, it uses `FetchContent` to get GoogleTest v1.14.0.
The first configure for a fresh fallback build tree may need network access.
After that, CMake reuses the downloaded source under the build tree.

GitHub Actions caches `build/_deps/googletest-src` for jobs that build tests, so
successful CI runs can reuse the GoogleTest checkout when the cache key still
matches.

For an offline or cached test build, point CMake at an existing GoogleTest
source checkout:

```sh
cmake -S . -B build \
  -DANOSECUREKIT_BUILD_TESTS=ON \
  -DFETCHCONTENT_SOURCE_DIR_GOOGLETEST=/path/to/googletest-src
```

For package-only builds that do not need tests, disable tests:

```sh
cmake -S . -B build-install-only -DBUILD_TESTING=OFF -DANOSECUREKIT_BUILD_TESTS=OFF
```

## Install

```sh
cmake --install build --prefix /path/to/prefix --config Release
```

## Release

Release automation runs on version tags matching `v*`. A tag push runs the CI
matrix, gathers package artifacts, writes `SHA256SUMS.txt`, creates GitHub
artifact attestations for release assets, writes a release SPDX SBOM, and
creates or updates the GitHub Release.

The tag version must match the CMake project version. For example,
`project(... VERSION 0.3.0)` should be released with tag `v0.3.0`.

Local release preflight:

```sh
cmake --build build --config Release --target release-preflight
```

For the full release procedure, see
[docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md).
For user-side artifact verification, see
[docs/VERIFY_RELEASE.md](docs/VERIFY_RELEASE.md).
The release notes source of truth is
[docs/RELEASE_NOTES.md](docs/RELEASE_NOTES.md); GitHub Release notes should be
edited to match it when generated notes are too thin.

Package manager recipe drafts are generated by `release-preflight` under
`<build>/package-check/package-recipes`. Publish them only after the matching
GitHub Release assets are uploaded, checksum-verified, and attested.

Security issues should not be reported through public GitHub issues. See
[SECURITY.md](SECURITY.md) for the reporting policy.

## CLI

When installed, AnoSecureKit provides a small `anosecurekit` utility executable.
See [docs/CLI.md](docs/CLI.md) for command examples, file recipes, stdin/stdout
behavior, exit codes, and verification commands.

## Consume With CMake

From an installed package:

```cmake
find_package(anosecurekit CONFIG REQUIRED)

add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE anosecurekit::anosecurekit)
```

From a source checkout:

```cmake
add_subdirectory(path/to/anosecurekit)

add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE anosecurekit::anosecurekit)
```

From a release source archive with CMake `FetchContent`:

```cmake
include(FetchContent)

FetchContent_Declare(
  anosecurekit
  URL https://github.com/anothel/AnoSecureKit-Community/releases/download/v0.3.0/anosecurekit-0.3.0-source.tar.gz
  URL_HASH SHA256=<release archive checksum>)

FetchContent_MakeAvailable(anosecurekit)

add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE anosecurekit::anosecurekit)
```

Use the checksum from the matching `SHA256SUMS.txt` release asset before
building from a release source archive. On single-config generators, set
`CMAKE_BUILD_TYPE=Release` when linking against a Release package archive.

## Examples

The checked C++ example lives in [examples/basic](examples/basic):

```sh
cmake --build build --config Release --target examples-check
```

## C++ Example

```cpp
#include "anosecurekit/anosecurekit.hpp"

#include <cstddef>
#include <iostream>
#include <string>
#include <string_view>

anosecurekit::bytes bytes_from_text(std::string_view text)
{
	anosecurekit::bytes out;
	out.reserve(text.size());
	for (unsigned char ch : text)
	{
		out.push_back(static_cast<std::byte>(ch));
	}
	return out;
}

int main()
{
	const anosecurekit::bytes message = bytes_from_text("hello anosecurekit");

	const std::string hex = anosecurekit::hex_encode(message);
	const anosecurekit::bytes from_hex = anosecurekit::hex_decode(hex);

	const std::string b64 = anosecurekit::base64_encode(from_hex);
	const anosecurekit::bytes from_b64 = anosecurekit::base64_decode(b64);

	const anosecurekit::digest256 digest = anosecurekit::sha256(from_b64);
	std::cout << "sha256=" << anosecurekit::hex_encode(digest) << "\n";

	const std::string token = anosecurekit::random_token(32);
	std::cout << "token=" << token << "\n";

	const anosecurekit::key256 key = anosecurekit::generate_key();
	const anosecurekit::bytes aad = bytes_from_text("record:v1");
	const anosecurekit::bytes packet = anosecurekit::encrypt(from_b64, key, aad);
	const anosecurekit::bytes plaintext = anosecurekit::decrypt(packet, key, aad);

	std::cout << "round trip bytes=" << plaintext.size() << "\n";
}
```

`bytes_from_text` is example-side code. AnoSecureKit accepts byte spans and does not
define text encoding conversion helpers in v1.

## Streaming Packet Example

Most callers should use one-shot `anosecurekit::decrypt` or path-based
`anosecurekit::open_file` first. Packet streaming is for callers that must process
an `SKT1` packet incrementally and can buffer plaintext until authentication
finishes.

```cpp
anosecurekit::packet_encryptor encryptor(key, aad);
anosecurekit::bytes packet = encryptor.begin();
anosecurekit::bytes chunk = encryptor.update(plaintext);
anosecurekit::bytes tag = encryptor.finalize();
packet.insert(packet.end(), chunk.begin(), chunk.end());
packet.insert(packet.end(), tag.begin(), tag.end());

anosecurekit::packet_decryptor decryptor(key, aad);
std::span<const std::byte> packet_span(packet);
decryptor.begin(packet_span.first(17));
anosecurekit::bytes roundtrip = decryptor.update(packet_span.subspan(17, plaintext.size()));
anosecurekit::bytes trailing = decryptor.finalize(packet_span.last(16));
roundtrip.insert(roundtrip.end(), trailing.begin(), trailing.end());
```

`packet_encryptor::begin()` returns the serialized `SKT1` packet prefix
(`header + nonce`). `packet_decryptor::begin()` expects that same 17-byte
prefix. `packet_decryptor::update()` returns decrypted bytes before tag
verification completes, so callers must treat those bytes as untrusted until
`finalize()` succeeds.

Wrong:

```cpp
anosecurekit::bytes plaintext = decryptor.update(ciphertext_chunk);
write_to_user_or_disk(plaintext); // plaintext is not authenticated yet
decryptor.finalize(tag);
```

Right:

```cpp
anosecurekit::bytes pending = decryptor.update(ciphertext_chunk);
anosecurekit::bytes tail = decryptor.finalize(tag);
pending.insert(pending.end(), tail.begin(), tail.end());
write_to_user_or_disk(pending); // authentication has succeeded
```

## Public API

```cpp
namespace anosecurekit {

using bytes = std::vector<std::byte>;
using key256 = std::array<std::byte, 32>;
using digest256 = std::array<std::byte, 32>;

enum class error_code {
	invalid_input,
	invalid_encoding,
	invalid_packet,
	authentication_failed,
	backend_failure,
};

class error : public std::runtime_error {
public:
	error(error_code code, std::string message);
	error_code code() const noexcept;
};

} // namespace anosecurekit

std::string anosecurekit::hex_encode(std::span<const std::byte> input);
anosecurekit::bytes anosecurekit::hex_decode(std::string_view input);

std::string anosecurekit::base64_encode(std::span<const std::byte> input);
anosecurekit::bytes anosecurekit::base64_decode(std::string_view input);
std::string anosecurekit::base64url_encode(std::span<const std::byte> input);
anosecurekit::bytes anosecurekit::base64url_decode(std::string_view input);

anosecurekit::digest256 anosecurekit::sha256(std::span<const std::byte> input);
anosecurekit::digest256 anosecurekit::hmac_sha256(
	std::span<const std::byte> key,
	std::span<const std::byte> input);
anosecurekit::bytes anosecurekit::hkdf_sha256(
	std::span<const std::byte> key_material,
	std::span<const std::byte> salt,
	std::span<const std::byte> info,
	std::size_t output_size);

bool anosecurekit::constant_time_equal(
	std::span<const std::byte> left,
	std::span<const std::byte> right);

anosecurekit::bytes anosecurekit::random_bytes(std::size_t size);
anosecurekit::key256 anosecurekit::generate_key();
std::string anosecurekit::random_token(std::size_t byte_size);

std::string_view anosecurekit::version() noexcept;
int anosecurekit::version_major() noexcept;
int anosecurekit::version_minor() noexcept;
int anosecurekit::version_patch() noexcept;

anosecurekit::bytes anosecurekit::encrypt(
	std::span<const std::byte> plaintext,
	const anosecurekit::key256 &key,
	std::span<const std::byte> aad = {});

anosecurekit::bytes anosecurekit::decrypt(
	std::span<const std::byte> packet,
	const anosecurekit::key256 &key,
	std::span<const std::byte> aad = {});

namespace anosecurekit {

class packet_encryptor {
public:
	explicit packet_encryptor(const key256 &key, std::span<const std::byte> aad = {});
	~packet_encryptor();
	packet_encryptor(packet_encryptor &&) noexcept;
	packet_encryptor &operator=(packet_encryptor &&) noexcept;
	packet_encryptor(const packet_encryptor &) = delete;
	packet_encryptor &operator=(const packet_encryptor &) = delete;
	bytes begin();
	bytes update(std::span<const std::byte> plaintext);
	bytes finalize();
};

class packet_decryptor {
public:
	explicit packet_decryptor(const key256 &key, std::span<const std::byte> aad = {});
	~packet_decryptor();
	packet_decryptor(packet_decryptor &&) noexcept;
	packet_decryptor &operator=(packet_decryptor &&) noexcept;
	packet_decryptor(const packet_decryptor &) = delete;
	packet_decryptor &operator=(const packet_decryptor &) = delete;
	void begin(std::span<const std::byte> packet_prefix);
	bytes update(std::span<const std::byte> ciphertext);
	bytes finalize(std::span<const std::byte> tag);
};

} // namespace anosecurekit

anosecurekit::bytes anosecurekit::wrap_key(
	const anosecurekit::key256 &key_to_wrap,
	const anosecurekit::key256 &wrapping_key,
	std::span<const std::byte> aad = {});

anosecurekit::key256 anosecurekit::unwrap_key(
	std::span<const std::byte> packet,
	const anosecurekit::key256 &wrapping_key,
	std::span<const std::byte> aad = {});

void anosecurekit::seal_file(
	const std::filesystem::path &input,
	const std::filesystem::path &output,
	const anosecurekit::key256 &key,
	std::span<const std::byte> aad = {});

void anosecurekit::seal_file(
	std::istream &input,
	std::ostream &output,
	const anosecurekit::key256 &key,
	std::span<const std::byte> aad = {});

void anosecurekit::open_file(
	const std::filesystem::path &input,
	const std::filesystem::path &output,
	const anosecurekit::key256 &key,
	std::span<const std::byte> aad = {});

void anosecurekit::open_file(
	std::istream &input,
	std::ostream &output,
	const anosecurekit::key256 &key,
	std::span<const std::byte> aad = {});

void anosecurekit::seal_file_with_password(
	const std::filesystem::path &input,
	const std::filesystem::path &output,
	std::span<const std::byte> password,
	std::span<const std::byte> aad = {});

void anosecurekit::seal_file_with_password(
	std::istream &input,
	std::ostream &output,
	std::span<const std::byte> password,
	std::span<const std::byte> aad = {});

void anosecurekit::open_file_with_password(
	const std::filesystem::path &input,
	const std::filesystem::path &output,
	std::span<const std::byte> password,
	std::span<const std::byte> aad = {});

void anosecurekit::open_file_with_password(
	std::istream &input,
	std::ostream &output,
	std::span<const std::byte> password,
	std::span<const std::byte> aad = {});
```

`anosecurekit::error` reports library failures with `anosecurekit::error_code`.

The base API stays free-function oriented. Hex and Base64 decoders are strict
only: malformed or non-canonical input raises `anosecurekit::error`. If permissive
decoding or non-throwing result APIs are needed later, they should be added as
explicitly named variants instead of changing these functions.

The packet API intentionally keeps the general `encrypt` and `decrypt` names.
Incremental packet processing uses distinct `packet_encryptor` and
`packet_decryptor` names instead of overloading those free functions. Both
streaming classes are move-only and one-shot.

`anosecurekit::wrap_key` uses the same `SKT1` packet format as `encrypt` to wrap a
single 32-byte `anosecurekit::key256` with another 32-byte wrapping key. It accepts
optional AAD. `anosecurekit::unwrap_key` authenticates and decrypts the packet, then
rejects packets that do not contain exactly one 32-byte key.

`anosecurekit::random_token` returns an unpadded Base64URL string from
cryptographically secure random bytes. It rejects `byte_size == 0` with
`anosecurekit::error_code::invalid_input`.

`anosecurekit::version()` and the numeric version helpers return the package
version compiled from the CMake project version. The CLI `anosecurekit --version`
uses the same runtime value.

The compatibility reference for serialized `SKT1`, `SKF1`, and `SKP1` data is
[docs/FORMAT.md](docs/FORMAT.md). Security boundaries and operational limits are
documented in [docs/SECURITY_MODEL.md](docs/SECURITY_MODEL.md).
Public API shape decisions are documented in
[docs/PUBLIC_API_POLICY.md](docs/PUBLIC_API_POLICY.md). OpenSSL provider policy
is documented in
[docs/OPENSSL_POLICY.md](docs/OPENSSL_POLICY.md).
Internal ownership boundaries and split gates are documented in
[docs/INTERNALS.md](docs/INTERNALS.md). The internal backend/provider design is
documented in [docs/BACKEND_ARCHITECTURE.md](docs/BACKEND_ARCHITECTURE.md).

## AES-256-GCM Packet Format

AnoSecureKit AES-GCM encryption returns one serialized packet:

| Offset | Size | Field | Value |
| --- | ---: | --- | --- |
| 0 | 4 | Magic | `SKT1` |
| 4 | 1 | Version | `0x01` |
| 5 | 12 | Nonce | Generated per packet |
| 17 | N | Ciphertext | AES-256-GCM ciphertext |
| 17 + N | 16 | Tag | AES-GCM authentication tag |

The caller supplies a 32-byte key. AnoSecureKit generates the packet nonce internally.
The packet header and caller-provided AAD are authenticated. AAD is not stored
in the packet. Decryption requires the same AAD used during encryption.

## Packet Streaming

`packet_encryptor` and `packet_decryptor` use the same `SKT1` wire format as the
free functions, but split it into:

- `begin()` / `begin(packet_prefix)` for the 17-byte packet prefix.
- `update()` for ciphertext or plaintext chunks.
- `finalize()` for the 16-byte authentication tag.

The classes are move-only and one-shot. Construction fixes the key and AAD for
the whole packet. Invalid sequencing raises
`anosecurekit::error_code::invalid_input`. Malformed prefixes or malformed tag
sizes raise `anosecurekit::error_code::invalid_packet`.

`packet_decryptor::update()` yields plaintext before authentication is complete.
Those bytes are UNVERIFIED PLAINTEXT. Callers must not release, persist, parse,
execute, display, or trust decrypted bytes until `finalize(tag)` returns
successfully.

## SKF1 File Format

`anosecurekit::seal_file` writes an `SKF1` file. It uses a fixed 1 MiB chunk size,
a random per-file salt, HKDF-SHA256 to derive a per-file key, and AES-256-GCM
for each chunk. The chunk nonce is an 8-byte random file nonce prefix plus a
32-bit big-endian chunk index.

File header:

| Offset | Size | Field | Value |
| --- | ---: | --- | --- |
| 0 | 4 | Magic | `SKF1` |
| 4 | 1 | Version | `0x01` |
| 5 | 1 | Algorithm | `0x01` for AES-256-GCM with HKDF-SHA256 |
| 6 | 4 | Chunk size | `0x00100000` big-endian, 1 MiB |
| 10 | 32 | Salt | Random per file |
| 42 | 8 | Nonce prefix | Random per file |

Each chunk record:

| Offset | Size | Field | Value |
| --- | ---: | --- | --- |
| 0 | 4 | Chunk index | Big-endian, starts at 0 |
| 4 | 4 | Plaintext size | Big-endian, 0 to 1 MiB |
| 8 | 1 | Final flag | `0x00` non-final, `0x01` final |
| 9 | N | Ciphertext | AES-256-GCM ciphertext |
| 9 + N | 16 | Tag | AES-GCM authentication tag |

The file header, chunk index, plaintext size, final flag, and caller-provided
AAD are authenticated with every chunk. `open_file` rejects malformed headers,
unsupported versions, unsupported chunk sizes, truncated records, non-monotonic
chunk indexes, non-final short chunks, chunks after the final chunk, missing
final chunks, appended data, wrong keys, wrong AAD, and tag failures. Path
overload output files must not already exist; AnoSecureKit writes a unique
temporary file in the output directory and commits it to the final output path
only after successful completion. Stream overloads operate on caller-provided
streams and do not perform output path checks or temporary-file renames. When
opening from a stream, callers should treat plaintext output as accepted only
after the function returns successfully.

## SKP1 Password File Format

`anosecurekit::seal_file_with_password` writes an `SKP1` file. It uses the same
1 MiB chunk record format and AES-256-GCM chunk encryption as `SKF1`, but
derives the 32-byte file key from caller-provided password bytes using scrypt.
Password bytes are accepted exactly as supplied by the caller; AnoSecureKit
does not trim, normalize, encode, or prompt for passwords. Empty passwords are
rejected with `anosecurekit::error_code::invalid_input`.

Fixed scrypt parameters:

- `N = 32768`
- `r = 8`
- `p = 1`
- `maxmem = 64 MiB`

File header:

| Offset | Size | Field | Value |
| --- | ---: | --- | --- |
| 0 | 4 | Magic | `SKP1` |
| 4 | 1 | Version | `0x01` |
| 5 | 1 | Cipher | `0x01` for AES-256-GCM |
| 6 | 1 | KDF | `0x01` for scrypt |
| 7 | 1 | Flags | `0x00` |
| 8 | 4 | Chunk size | `0x00100000` big-endian, 1 MiB |
| 12 | 32 | Salt | Random per file |
| 44 | 8 | Nonce prefix | Random per file |
| 52 | 4 | scrypt N | `32768` big-endian |
| 56 | 4 | scrypt r | `8` big-endian |
| 60 | 4 | scrypt p | `1` big-endian |

The `SKP1` header, chunk index, plaintext size, final flag, and caller-provided
AAD are authenticated with every chunk. `open_file_with_password` rejects
malformed headers, unsupported versions, unsupported cipher IDs, unsupported KDF
IDs, unsupported flags, unsupported scrypt parameters, truncated records,
non-monotonic chunk indexes, non-final short chunks, chunks after the final
chunk, missing final chunks, appended data, wrong passwords, wrong AAD, and tag
failures. Wrong passwords, wrong AAD, and tag failures report the same generic
`anosecurekit::error_code::authentication_failed` message as other file
authentication failures.

## Security Boundaries

AnoSecureKit currently uses OpenSSL 3.x as its default crypto backend. It does not:

- Store keys.
- Provide a general-purpose password hashing API.
- Provide a reusable password KDF API outside `SKP1` file encryption.
- Prevent key copies.
- Guarantee memory erasure.
- Configure OpenSSL providers.
- Hide plaintext from process memory.

AnoSecureKit does not scrub, lock, or otherwise guarantee erasure of key material,
derived keys, plaintext, or intermediate buffers from process memory.

Path-based file APIs and CLI file commands refuse existing output paths and
remove AnoSecureKit-owned temporary output after failures. Path-based file APIs
flush AnoSecureKit-owned temporary output before committing it and use platform
commit syncing where practical, but they do not guarantee survival across power
loss or storage-device failure. If a post-commit directory sync fails on a
platform that supports it, AnoSecureKit reports `backend_failure` and the output
path may already exist. Stream overloads and standard-stream CLI usage operate
on caller-provided streams, so callers remain responsible for discarding
untrusted output when an operation fails.

Applications remain responsible for key lifecycle, provider configuration,
process isolation, persistence, backups, logging policy, and threat modeling.

`anosecurekit::constant_time_equal` avoids content-dependent early exits for the
bytes it compares. It checks lengths before comparing bytes, so callers must not
treat input length as secret.

## Password KDF Scope

AnoSecureKit's password support is limited to `SKP1` file encryption. It does not
expose a reusable password KDF API or a password hashing API. `SKP1` currently
uses scrypt with fixed parameters recorded in the file header and
rejects headers that request different parameters.

Future password formats should be versioned as new file formats or explicit
format revisions instead of silently changing `SKP1` behavior. Argon2id,
PBKDF2, prompt handling, environment-variable password loading, password text
arguments, and tunable scrypt parameters are intentionally outside this API
slice. Future password-file KDF profiles must pass the downgrade, bounds, and
fixture gates in `docs/KDF_AGILITY.md` before implementation.

## OpenSSL Providers and Backend Errors

AnoSecureKit uses OpenSSL's default library context and the provider configuration
already active in the process. It does not load providers, create an
`OSSL_LIB_CTX`, set property queries, or switch provider selections.

Applications that require custom provider selection must configure OpenSSL before
calling AnoSecureKit. AES-256-GCM, SHA-256, HMAC-SHA-256, HKDF-SHA-256, scrypt,
and OpenSSL's random byte APIs must be available from that configuration.

OpenSSL allocation, initialization, cipher, digest, MAC, KDF, or
random-generation failures are reported as
`anosecurekit::error_code::backend_failure`. AnoSecureKit does not add OpenSSL
error-queue details to public exception messages. AEAD packet and file
authentication failures are reported as
`anosecurekit::error_code::authentication_failed` with generic messages. Malformed
or unsupported packet and file structure is reported as
`anosecurekit::error_code::invalid_packet`.

## Compatibility Fixtures

Known v1 wire-format vectors live in `tests/fixtures` as lowercase hex files.
The test suite reads these files for `SKT1`, `SKF1`, `SKP1`, and key wrapping
coverage instead of keeping serialized packets inline in test source. Fixture
naming, minimum family counts, and update policy are documented in
`tests/fixtures/README.md`. `FixtureInventory.*` tests enforce the documented
inventory and minimum family counts.

## Continuous Integration

GitHub Actions runs the main supported build and package surfaces:

- Ubuntu GCC Release.
- Ubuntu GCC Debug.
- Ubuntu Clang Release.
- Windows MSVC Release with vcpkg OpenSSL.
- Install and consumer-project checks.
- Install-only package and consumer check with tests disabled.
- Linux static-library package and consumer check.
- Windows shared-library package and consumer check.
- Linux Clang Debug sanitizer job with AddressSanitizer and UndefinedBehaviorSanitizer.
- macOS AppleClang Release package-check job with Homebrew OpenSSL 3.
- CPack binary and source package artifact uploads.

`release-workflow-check` locally guards the release workflow shape, artifact
version checks, release provenance attestation wiring, and current GitHub Action
major versions. CodeQL runs in a separate `CodeQL` workflow on pushes and pull
requests to `main`, plus a weekly schedule, with manual CMake configure/build
steps.

Local preflight:

```sh
cmake -S . -B build -DANOSECUREKIT_BUILD_TESTS=ON
cmake --build build --config Release --target release-preflight
```

On Windows with dynamically linked OpenSSL, pass `ANOSECUREKIT_OPENSSL_RUNTIME_DIR`
when configuring so `check` and `package-check` can run CLI and consumer
executables with the OpenSSL DLL directory on `PATH`.

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md) for forward-looking work.
Completed work is kept in Git history instead of the active roadmap.
Website, guide, and browser-local tool planning lives in
[docs/WEB_ROADMAP.md](docs/WEB_ROADMAP.md).
