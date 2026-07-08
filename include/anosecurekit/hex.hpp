// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_HEX_HPP_
#define ANOSECUREKIT_HEX_HPP_

#include <cstddef>
#include <span>
#include <string>
#include <string_view>

#include "anosecurekit/export.hpp"
#include "anosecurekit/types.hpp"

namespace anosecurekit
{

ANOSECUREKIT_API std::string hex_encode(std::span<const std::byte> input);
ANOSECUREKIT_API bytes hex_decode(std::string_view input);

} // namespace anosecurekit

#endif // ANOSECUREKIT_HEX_HPP_
