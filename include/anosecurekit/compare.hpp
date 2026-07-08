// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_COMPARE_HPP_
#define ANOSECUREKIT_COMPARE_HPP_

#include <cstddef>
#include <span>

#include "anosecurekit/export.hpp"

namespace anosecurekit
{

// Avoids content-dependent early exits for compared bytes. Input lengths are
// checked first and must not be secret.
ANOSECUREKIT_API bool constant_time_equal(std::span<const std::byte> left, std::span<const std::byte> right);

} // namespace anosecurekit

#endif // ANOSECUREKIT_COMPARE_HPP_
