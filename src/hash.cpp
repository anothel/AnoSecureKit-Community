// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/hash.hpp"

#include "crypto_backend.hpp"

namespace anosecurekit
{

digest256 sha256(std::span<const std::byte> input)
{
	return detail::crypto_backend::sha256(input);
}

bytes hkdf_sha256(std::span<const std::byte> key_material, std::span<const std::byte> salt, std::span<const std::byte> info, std::size_t output_size)
{
	return detail::crypto_backend::hkdf_sha256(key_material, salt, info, output_size);
}

digest256 hmac_sha256(std::span<const std::byte> key, std::span<const std::byte> input)
{
	return detail::crypto_backend::hmac_sha256(key, input);
}

} // namespace anosecurekit
