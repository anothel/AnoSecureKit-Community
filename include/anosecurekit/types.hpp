// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_TYPES_HPP_
#define ANOSECUREKIT_TYPES_HPP_

#include <array>
#include <cstddef>
#include <span>
#include <vector>

namespace anosecurekit
{

using bytes = std::vector<std::byte>;
using key256 = std::array<std::byte, 32>;
using digest256 = std::array<std::byte, 32>;

} // namespace anosecurekit

#endif // ANOSECUREKIT_TYPES_HPP_
