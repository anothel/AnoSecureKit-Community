// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/random.hpp"

#include <cstddef>
#include <string>
#include <string_view>
#include <type_traits>

#include <gtest/gtest.h>

#include "anosecurekit/base64.hpp"
#include "anosecurekit/error.hpp"

namespace
{

bool is_base64url_text(std::string_view text)
{
	for (const char ch : text)
	{
		const bool is_alpha = (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z');
		const bool is_digit = ch >= '0' && ch <= '9';
		if (!is_alpha && !is_digit && ch != '-' && ch != '_')
		{
			return false;
		}
	}
	return true;
}

} // namespace

TEST(Random, ReturnsRequestedNumberOfBytes)
{
	EXPECT_TRUE(anosecurekit::random_bytes(0).empty());
	EXPECT_EQ(anosecurekit::random_bytes(1).size(), 1u);
	EXPECT_EQ(anosecurekit::random_bytes(16).size(), 16u);
	EXPECT_EQ(anosecurekit::random_bytes(1024).size(), 1024u);
}

TEST(Random, GenerateKeyReturnsKey256)
{
	static_assert(std::is_same_v<decltype(anosecurekit::generate_key()), anosecurekit::key256>);

	const anosecurekit::key256 key = anosecurekit::generate_key();
	EXPECT_EQ(key.size(), 32u);
}

TEST(Random, RandomTokenReturnsBase64UrlForRequestedByteSize)
{
	for (const std::size_t byte_size : {1u, 2u, 3u, 32u})
	{
		const std::string token = anosecurekit::random_token(byte_size);

		EXPECT_EQ(anosecurekit::base64url_decode(token).size(), byte_size);
		EXPECT_TRUE(is_base64url_text(token));
		EXPECT_EQ(token.find('='), std::string::npos);
	}
}

TEST(Random, RandomTokenRejectsZeroSize)
{
	EXPECT_THROW(
	    {
		    try
		    {
			    (void)anosecurekit::random_token(0);
		    }
		    catch (const anosecurekit::error &ex)
		    {
			    EXPECT_EQ(ex.code(), anosecurekit::error_code::invalid_input);
			    throw;
		    }
	    },
	    anosecurekit::error);
}
