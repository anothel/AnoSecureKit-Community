// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/version.hpp"

namespace anosecurekit
{

std::string_view version() noexcept
{
	return ANOSECUREKIT_VERSION;
}

int version_major() noexcept
{
	return ANOSECUREKIT_VERSION_MAJOR;
}

int version_minor() noexcept
{
	return ANOSECUREKIT_VERSION_MINOR;
}

int version_patch() noexcept
{
	return ANOSECUREKIT_VERSION_PATCH;
}

} // namespace anosecurekit
