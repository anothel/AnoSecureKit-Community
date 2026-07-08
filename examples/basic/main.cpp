// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/anosecurekit.hpp"

#include <cstddef>
#include <iostream>
#include <string_view>

namespace
{

anosecurekit::bytes bytes_from_text(std::string_view text)
{
	anosecurekit::bytes out;
	out.reserve(text.size());
	for (unsigned char ch : text)
	{
		out.push_back(static_cast<std::byte>(ch));
	}
	return out;
}

} // namespace

int main()
{
	const anosecurekit::bytes message = bytes_from_text("hello anosecurekit");
	const anosecurekit::bytes aad = bytes_from_text("example:v1");
	const anosecurekit::key256 key = anosecurekit::generate_key();

	const anosecurekit::bytes packet = anosecurekit::encrypt(message, key, aad);
	const anosecurekit::bytes opened = anosecurekit::decrypt(packet, key, aad);
	if (opened != message)
	{
		return 1;
	}

	std::cout << "sha256=" << anosecurekit::hex_encode(anosecurekit::sha256(message)) << '\n';
	return 0;
}
