// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/base64.hpp"

#include "fuzz_utils.hpp"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t *data, std::size_t size)
{
	const anosecurekit::bytes bytes = anosecurekit::fuzz::bytes_from_data(data, size);
	(void)anosecurekit::base64url_encode(bytes);

	try
	{
		(void)anosecurekit::base64url_decode(anosecurekit::fuzz::string_from_data(data, size));
	}
	catch (const anosecurekit::error &)
	{
	}

	return 0;
}
