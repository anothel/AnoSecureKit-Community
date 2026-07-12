// SPDX-License-Identifier: MPL-2.0
#include <cstddef>
#include <span>
#include <string_view>

#include "anosecurekit/hash.hpp"
#include "anosecurekit/hex.hpp"
#include "anosecurekit/types.hpp"

namespace
{

anosecurekit::bytes ascii_bytes(std::string_view text)
{
	anosecurekit::bytes result;
	result.reserve(text.size());
	for (const char ch : text)
	{
		result.push_back(static_cast<std::byte>(ch));
	}
	return result;
}

} // namespace

int main()
{
	const auto digest = anosecurekit::sha256(ascii_bytes("abc"));
	return anosecurekit::hex_encode(std::span<const std::byte>(digest)) ==
	               "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
	           ? 0
	           : 1;
}
