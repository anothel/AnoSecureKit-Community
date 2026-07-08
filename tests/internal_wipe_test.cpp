// SPDX-License-Identifier: MPL-2.0
#include "../src/wipe.hpp"

#include <algorithm>
#include <cstddef>

#include <gtest/gtest.h>

TEST(InternalWipe, OverwritesByteBuffer)
{
	anosecurekit::bytes data{std::byte{0x11}, std::byte{0x22}, std::byte{0x33}};

	anosecurekit::internal::secure_wipe(data);

	EXPECT_TRUE(std::all_of(data.begin(), data.end(), [](std::byte value) { return value == std::byte{0}; }));
}
