// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_VERSION_HPP_
#define ANOSECUREKIT_VERSION_HPP_

#include <string_view>

#include "anosecurekit/export.hpp"

namespace anosecurekit
{

ANOSECUREKIT_API std::string_view version() noexcept;
ANOSECUREKIT_API int version_major() noexcept;
ANOSECUREKIT_API int version_minor() noexcept;
ANOSECUREKIT_API int version_patch() noexcept;

} // namespace anosecurekit

#endif // ANOSECUREKIT_VERSION_HPP_
