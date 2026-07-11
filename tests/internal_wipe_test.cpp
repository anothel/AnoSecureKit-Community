// SPDX-License-Identifier: MPL-2.0
#include "../src/internal/secure_wipe.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <span>

#include <gtest/gtest.h>

namespace
{

bool all_zero(std::span<const std::byte> data)
{
	return std::all_of(data.begin(), data.end(), [](std::byte value) { return value == std::byte{0}; });
}

} // namespace

TEST(InternalWipe, OverwritesByteBuffer)
{
	anosecurekit::bytes data{std::byte{0x11}, std::byte{0x22}, std::byte{0x33}};

	anosecurekit::internal::secure_wipe(data);

	EXPECT_TRUE(all_zero(data));
}

TEST(InternalWipe, OverwritesFixedArray)
{
	std::array<std::byte, 4> data{
		std::byte{0x11}, std::byte{0x22}, std::byte{0x33}, std::byte{0x44}};

	anosecurekit::internal::secure_wipe(data);

	EXPECT_TRUE(all_zero(data));
}

TEST(InternalWipe, AcceptsEmptySpan)
{
	anosecurekit::internal::secure_wipe(std::span<std::byte>{});
}

TEST(InternalWipe, WipeOnExitOverwritesBuffer)
{
	std::array<std::byte, 3> data{std::byte{0x41}, std::byte{0x42}, std::byte{0x43}};
	{
		const anosecurekit::internal::wipe_on_exit guard{std::span<std::byte>(data)};
	}

	EXPECT_TRUE(all_zero(data));
}
