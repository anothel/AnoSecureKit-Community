// SPDX-License-Identifier: MPL-2.0
#include "fuzz/fuzz_utils.hpp"

#include <gtest/gtest.h>

#include <string>
#include <string_view>

TEST(FuzzFixtureAdapter, DecodesAllAcceptedWhitespaceBeforeHexDecode)
{
	const std::string input = " \t53\n4b\r54\f31\v01\n";
	const anosecurekit::bytes expected{
	    std::byte{0x53}, std::byte{0x4b}, std::byte{0x54}, std::byte{0x31}, std::byte{0x01}};
	EXPECT_EQ(anosecurekit::fuzz::raw_or_decoded_fixture(
	              reinterpret_cast<const std::uint8_t *>(input.data()), input.size()),
	    expected);
}

TEST(FuzzFixtureAdapter, PreservesNonFixtureInputsAsRawBytes)
{
	for (const std::string_view input : {"", " \t\n", "abc", "AB", "xx", "00z0"})
	{
		const auto *data = reinterpret_cast<const std::uint8_t *>(input.data());
		EXPECT_EQ(anosecurekit::fuzz::raw_or_decoded_fixture(data, input.size()),
		    anosecurekit::fuzz::bytes_from_data(data, input.size()));
	}
}
