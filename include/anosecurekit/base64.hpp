// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_BASE64_HPP_
#define ANOSECUREKIT_BASE64_HPP_

#include <cstddef>
#include <span>
#include <string>
#include <string_view>

#include "anosecurekit/export.hpp"
#include "anosecurekit/types.hpp"

namespace anosecurekit
{

ANOSECUREKIT_API std::string base64_encode(std::span<const std::byte> input);
ANOSECUREKIT_API bytes base64_decode(std::string_view input);
ANOSECUREKIT_API std::string base64url_encode(std::span<const std::byte> input);
ANOSECUREKIT_API bytes base64url_decode(std::string_view input);

} // namespace anosecurekit

#endif // ANOSECUREKIT_BASE64_HPP_
