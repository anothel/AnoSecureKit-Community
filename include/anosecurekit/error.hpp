// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_ERROR_HPP_
#define ANOSECUREKIT_ERROR_HPP_

#include <stdexcept>
#include <string>

#include "anosecurekit/export.hpp"

namespace anosecurekit
{

enum class error_code
{
	invalid_input,
	invalid_encoding,
	invalid_packet,
	authentication_failed,
	backend_failure,
};

class error : public std::runtime_error
{
public:
	ANOSECUREKIT_API error(error_code code, std::string message);

	[[nodiscard]] ANOSECUREKIT_API error_code code() const noexcept;

private:
	error_code code_;
};

} // namespace anosecurekit

#endif // ANOSECUREKIT_ERROR_HPP_
