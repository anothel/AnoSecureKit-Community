// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/aead.hpp"

#include "fuzz_utils.hpp"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t *data, std::size_t size)
{
	const anosecurekit::key256 key = anosecurekit::fuzz::key_from_seed(0x10);
	const anosecurekit::bytes packet = anosecurekit::fuzz::raw_or_decoded_fixture(data, size);

	try
	{
		(void)anosecurekit::decrypt(packet, key);
	}
	catch (const anosecurekit::error &)
	{
	}

	return 0;
}
