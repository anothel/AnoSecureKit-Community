// SPDX-License-Identifier: MPL-2.0
#include "secure_wipe.hpp"

#include <cstddef>

namespace anosecurekit::internal
{

void secure_wipe(std::span<std::byte> data) noexcept
{
	// Volatile byte writes are used deliberately so the compiler must preserve
	// the stores even when the buffer is dead immediately after this call.
	// This helper removes the previous OpenSSL dependency from common code; it
	// does not promise that every copy held elsewhere has also been erased.
	auto *current = reinterpret_cast<volatile unsigned char *>(data.data());
	for (std::size_t index = 0; index < data.size(); ++index)
	{
		current[index] = 0;
	}
}

} // namespace anosecurekit::internal
