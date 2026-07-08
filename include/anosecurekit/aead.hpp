// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_AEAD_HPP_
#define ANOSECUREKIT_AEAD_HPP_

#include <cstddef>
#include <span>

#include "anosecurekit/export.hpp"
#include "anosecurekit/types.hpp"

namespace anosecurekit
{

ANOSECUREKIT_API bytes encrypt(std::span<const std::byte> plaintext, const key256 &key, std::span<const std::byte> aad = {});

// Authenticates the whole SKT1 packet before returning plaintext. Wrong keys,
// wrong AAD, modified ciphertext, modified nonces, and tag failures report a
// generic authentication failure.
ANOSECUREKIT_API bytes decrypt(std::span<const std::byte> packet, const key256 &key, std::span<const std::byte> aad = {});

} // namespace anosecurekit

#endif // ANOSECUREKIT_AEAD_HPP_
