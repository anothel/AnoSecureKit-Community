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

// MSVC's std::runtime_error has no DLL class annotation. Keep our exception
// RTTI exported; users must share the supported compiler/CRT ABI.
#if defined(_MSC_VER) && defined(ANOSECUREKIT_SHARED)
#pragma warning(push)
#pragma warning(disable : 4275)
#endif
class ANOSECUREKIT_API error : public std::runtime_error
{
public:
	error(error_code code, std::string message);

	[[nodiscard]] error_code code() const noexcept;

private:
	error_code code_;
};

#if defined(_MSC_VER) && defined(ANOSECUREKIT_SHARED)
#pragma warning(pop)
#endif

} // namespace anosecurekit

#endif // ANOSECUREKIT_ERROR_HPP_
