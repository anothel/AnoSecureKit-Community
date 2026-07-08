// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_RANDOM_HPP_
#define ANOSECUREKIT_RANDOM_HPP_

#include <cstddef>
#include <string>

#include "anosecurekit/export.hpp"
#include "anosecurekit/types.hpp"

namespace anosecurekit
{

ANOSECUREKIT_API bytes random_bytes(std::size_t size);
ANOSECUREKIT_API key256 generate_key();
ANOSECUREKIT_API std::string random_token(std::size_t byte_size);

} // namespace anosecurekit

#endif // ANOSECUREKIT_RANDOM_HPP_
