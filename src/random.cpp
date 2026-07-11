// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/random.hpp"

#include "anosecurekit/base64.hpp"
#include "anosecurekit/error.hpp"

#include "backend/crypto_backend.hpp"

namespace anosecurekit
{

bytes random_bytes(std::size_t size)
{
	return detail::crypto_backend::random_bytes(size);
}

key256 generate_key()
{
	return detail::crypto_backend::generate_key();
}

std::string random_token(std::size_t byte_size)
{
	if (byte_size == 0)
	{
		throw error(error_code::invalid_input, "random token byte size must be greater than zero");
	}
	return base64url_encode(random_bytes(byte_size));
}

} // namespace anosecurekit
