// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_FILE_HPP_
#define ANOSECUREKIT_FILE_HPP_

#include <cstddef>
#include <filesystem>
#include <iosfwd>
#include <span>

#include "anosecurekit/export.hpp"
#include "anosecurekit/types.hpp"

namespace anosecurekit
{

ANOSECUREKIT_API void seal_file(
    const std::filesystem::path &input,
    const std::filesystem::path &output,
    const key256 &key,
    std::span<const std::byte> aad = {});

ANOSECUREKIT_API void seal_file(
    std::istream &input,
    std::ostream &output,
    const key256 &key,
    std::span<const std::byte> aad = {});

// Path overload refuses an existing output path, writes an AnoSecureKit-owned
// temporary file, and commits it only after authentication succeeds.
ANOSECUREKIT_API void open_file(
    const std::filesystem::path &input,
    const std::filesystem::path &output,
    const key256 &key,
    std::span<const std::byte> aad = {});

// Stream overload writes to caller-owned output; callers own rollback or
// discard policy if this function throws after writing bytes.
ANOSECUREKIT_API void open_file(
    std::istream &input,
    std::ostream &output,
    const key256 &key,
    std::span<const std::byte> aad = {});

// Authenticates the complete SKF1 input without creating or exposing plaintext
// output. Success returns normally; failures use the same error contract as
// open_file.
ANOSECUREKIT_API void verify_file(
    const std::filesystem::path &input,
    const key256 &key,
    std::span<const std::byte> aad = {});

// Consumes the complete SKF1 stream and discards authenticated plaintext inside
// AnoSecureKit. No caller-owned output stream is involved.
ANOSECUREKIT_API void verify_file(
    std::istream &input,
    const key256 &key,
    std::span<const std::byte> aad = {});

// Password bytes are used exactly as supplied: no trimming, normalization,
// prompting, encoding conversion, or environment lookup.
ANOSECUREKIT_API void seal_file_with_password(
    const std::filesystem::path &input,
    const std::filesystem::path &output,
    std::span<const std::byte> password,
    std::span<const std::byte> aad = {});

ANOSECUREKIT_API void seal_file_with_password(
    std::istream &input,
    std::ostream &output,
    std::span<const std::byte> password,
    std::span<const std::byte> aad = {});

// Path overload has the same no-overwrite and temporary-file commit behavior
// as open_file.
ANOSECUREKIT_API void open_file_with_password(
    const std::filesystem::path &input,
    const std::filesystem::path &output,
    std::span<const std::byte> password,
    std::span<const std::byte> aad = {});

// Stream overload writes to caller-owned output; callers own rollback or
// discard policy if this function throws after writing bytes.
ANOSECUREKIT_API void open_file_with_password(
    std::istream &input,
    std::ostream &output,
    std::span<const std::byte> password,
    std::span<const std::byte> aad = {});

// Authenticates the complete SKP1 input without creating or exposing plaintext
// output. Password bytes and failure behavior match open_file_with_password.
ANOSECUREKIT_API void verify_file_with_password(
    const std::filesystem::path &input,
    std::span<const std::byte> password,
    std::span<const std::byte> aad = {});

// Consumes the complete SKP1 stream and discards authenticated plaintext inside
// AnoSecureKit. No caller-owned output stream is involved.
ANOSECUREKIT_API void verify_file_with_password(
    std::istream &input,
    std::span<const std::byte> password,
    std::span<const std::byte> aad = {});

} // namespace anosecurekit

#endif // ANOSECUREKIT_FILE_HPP_
