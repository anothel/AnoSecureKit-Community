// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/file.hpp"

#include <sstream>

#include "fuzz_utils.hpp"

namespace
{

void try_open_file(const anosecurekit::bytes &data)
{
	const std::string input_bytes(reinterpret_cast<const char *>(data.data()), data.size());
	std::istringstream input(input_bytes, std::ios::in | std::ios::binary);
	std::ostringstream output(std::ios::out | std::ios::binary);
	const anosecurekit::key256 key = anosecurekit::fuzz::key_from_seed(0x20);

	try
	{
		anosecurekit::open_file(input, output, key);
	}
	catch (const anosecurekit::error &)
	{
	}
}

void try_open_password_file(const anosecurekit::bytes &data)
{
	if (data.size() >= 4 && data[0] == std::byte{'S'} && data[1] == std::byte{'K'} && data[2] == std::byte{'P'} &&
	    data[3] == std::byte{'1'} && data.size() >= 64)
	{
		return;
	}

	const std::string input_bytes(reinterpret_cast<const char *>(data.data()), data.size());
	std::istringstream input(input_bytes, std::ios::in | std::ios::binary);
	std::ostringstream output(std::ios::out | std::ios::binary);
	const anosecurekit::bytes password{std::byte{'f'}, std::byte{'u'}, std::byte{'z'}, std::byte{'z'}};

	try
	{
		anosecurekit::open_file_with_password(input, output, password);
	}
	catch (const anosecurekit::error &)
	{
	}
}

} // namespace

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t *data, std::size_t size)
{
	const anosecurekit::bytes payload = anosecurekit::fuzz::raw_or_decoded_fixture(data, size);
	try_open_file(payload);
	try_open_password_file(payload);
	return 0;
}
