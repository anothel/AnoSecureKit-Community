// SPDX-License-Identifier: MPL-2.0
// Opt-in, KDF-aware SKP1 fuzz lane. Never enable on the default fast fuzz path.
#include "anosecurekit/error.hpp"
#include "anosecurekit/file.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <sstream>
#include <string>
#include <string_view>

#include "fuzz_utils.hpp"

namespace
{
std::span<const std::byte> bytes_of(std::string_view text)
{
	return {reinterpret_cast<const std::byte *>(text.data()), text.size()};
}
} // namespace

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t *data, std::size_t size)
{
	// The fixed SKP1 scrypt profile is intentionally expensive. Keep its
	// corpus and wall-clock budget separate from the default file fuzzer.
	if (size > 8192)
	{
		return 0;
	}
	const auto packet = anosecurekit::fuzz::raw_or_decoded_fixture(data, size);
	if (packet.size() < 64 || packet.size() > 4096 || packet[0] != std::byte{'S'} ||
		packet[1] != std::byte{'K'} || packet[2] != std::byte{'P'} || packet[3] != std::byte{'1'})
	{
		return 0;
	}

	const std::string encoded{reinterpret_cast<const char *>(packet.data()), packet.size()};
	std::istringstream input(encoded, std::ios::in | std::ios::binary);
	// The verify-only API consumes and discards intermediate plaintext.
	// Password and AAD match the synthetic committed compatibility vector.
	try
	{
		anosecurekit::verify_file_with_password(input, bytes_of("known SKP1 password"), bytes_of("fixture:aad"));
	}
	catch (const anosecurekit::error &)
	{
		// Authentication and structural rejection are valid fuzz outcomes.
	}
	return 0;
}
