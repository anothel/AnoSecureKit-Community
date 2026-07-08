// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_HASH_HPP_
#define ANOSECUREKIT_HASH_HPP_

#include <cstddef>
#include <span>

#include "anosecurekit/export.hpp"
#include "anosecurekit/types.hpp"

namespace anosecurekit
{

ANOSECUREKIT_API digest256 sha256(std::span<const std::byte> input);
ANOSECUREKIT_API digest256 hmac_sha256(std::span<const std::byte> key, std::span<const std::byte> input);

// Derives exactly output_size bytes. output_size == 0 returns an empty vector.
ANOSECUREKIT_API bytes hkdf_sha256(
    std::span<const std::byte> key_material,
    std::span<const std::byte> salt,
    std::span<const std::byte> info,
    std::size_t output_size);

} // namespace anosecurekit

#endif // ANOSECUREKIT_HASH_HPP_
