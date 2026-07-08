// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/compare.hpp"
#include "anosecurekit/types.hpp"

#include <cstddef>
#include <initializer_list>

#include <gtest/gtest.h>

namespace
{

anosecurekit::bytes make_bytes(std::initializer_list<unsigned char> values)
{
	anosecurekit::bytes out;
	out.reserve(values.size());
	for (const unsigned char value : values)
	{
		out.push_back(static_cast<std::byte>(value));
	}
	return out;
}

} // namespace

TEST(Compare, EqualInputsReturnTrue)
{
	const anosecurekit::bytes left = make_bytes({0x00, 0x01, 0x80, 0xff});
	const anosecurekit::bytes right = make_bytes({0x00, 0x01, 0x80, 0xff});

	EXPECT_TRUE(anosecurekit::constant_time_equal(left, right));
}

TEST(Compare, SameLengthDifferentInputsReturnFalse)
{
	const anosecurekit::bytes left = make_bytes({0x00, 0x01, 0x80, 0xff});
	const anosecurekit::bytes right = make_bytes({0x00, 0x01, 0x81, 0xff});

	EXPECT_FALSE(anosecurekit::constant_time_equal(left, right));
}

TEST(Compare, DifferentLengthInputsReturnFalse)
{
	const anosecurekit::bytes left = make_bytes({0x00, 0x01, 0x80, 0xff});
	const anosecurekit::bytes right = make_bytes({0x00, 0x01, 0x80});

	EXPECT_FALSE(anosecurekit::constant_time_equal(left, right));
}

TEST(Compare, EmptyInputsReturnTrue)
{
	const anosecurekit::bytes left;
	const anosecurekit::bytes right;

	EXPECT_TRUE(anosecurekit::constant_time_equal(left, right));
}
