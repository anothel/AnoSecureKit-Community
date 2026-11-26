// SPDX-License-Identifier: MPL-2.0
#include <cstddef>
#include <fstream>
#include <iostream>
#include <iterator>
#include <span>
#include <sstream>
#include <string>
#include <string_view>

#include "anosecurekit/error.hpp"
#include "anosecurekit/file.hpp"
#include "anosecurekit/hex.hpp"
#include "fuzz_utils.hpp"

namespace
{
constexpr std::string_view fixture_password = "known SKP1 password";
constexpr std::string_view fixture_aad = "fixture:aad";
constexpr std::string_view expected_plaintext = "known SKP1 vector";

std::span<const std::byte> bytes_of(std::string_view text)
{
	return {reinterpret_cast<const std::byte *>(text.data()), text.size()};
}

std::istringstream packet_input(const anosecurekit::bytes &packet)
{
	return std::istringstream(
	    std::string(reinterpret_cast<const char *>(packet.data()), packet.size()), std::ios::binary);
}

bool verify(const anosecurekit::bytes &packet)
{
	auto input = packet_input(packet);
	anosecurekit::verify_file_with_password(input, bytes_of(fixture_password), bytes_of(fixture_aad));
	return input.eof();
}
} // namespace

int main(int argc, char **argv)
{
	if (argc != 2)
	{
		std::cerr << "Expected one SKP1 hex fixture path\n";
		return 1;
	}
	std::ifstream fixture(argv[1], std::ios::binary);
	std::string encoded{std::istreambuf_iterator<char>(fixture), {}};
	if (!fixture || !anosecurekit::fuzz::canonical_hex_fixture(encoded))
	{
		std::cerr << "Could not read the SKP1 hex fixture\n";
		return 1;
	}
	std::erase_if(encoded, anosecurekit::fuzz::is_ascii_space);
	auto packet = anosecurekit::hex_decode(encoded);
	try
	{
		if (!verify(packet))
		{
			std::cerr << "Known SKP1 vector was not verified through end of input\n";
			return 1;
		}
		auto input = packet_input(packet);
		std::ostringstream plaintext(std::ios::binary);
		anosecurekit::open_file_with_password(input, plaintext, bytes_of(fixture_password), bytes_of(fixture_aad));
		if (plaintext.view() != expected_plaintext)
		{
			std::cerr << "Known SKP1 vector plaintext mismatch\n";
			return 1;
		}
	}
	catch (const anosecurekit::error &)
	{
		std::cerr << "Known SKP1 vector verification failed\n";
		return 1;
	}
	std::cout << "Known SKP1 vector verified through end of input and plaintext matched\n";

	packet.back() ^= std::byte{1};
	try
	{
		verify(packet);
		std::cerr << "SKP1 vector with a modified final tag was accepted\n";
		return 1;
	}
	catch (const anosecurekit::error &error)
	{
		if (error.code() != anosecurekit::error_code::authentication_failed)
		{
			std::cerr << "Modified SKP1 final tag did not produce an authentication error\n";
			return 1;
		}
	}
	std::cout << "Modified SKP1 final tag rejected with authentication_failed\n";
}
