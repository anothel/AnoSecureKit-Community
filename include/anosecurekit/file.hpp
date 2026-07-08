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

} // namespace anosecurekit

#endif // ANOSECUREKIT_FILE_HPP_
