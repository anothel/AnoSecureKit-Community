// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/error.hpp"

#include <utility>

namespace anosecurekit
{

error::error(error_code code, std::string message) : std::runtime_error(std::move(message)), code_(code)
{
}

error_code error::code() const noexcept
{
	return code_;
}

} // namespace anosecurekit
