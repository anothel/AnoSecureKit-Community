// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/key_wrap.hpp"

#include <cstddef>
#include <string_view>
#include <utility>

#include <gtest/gtest.h>

#include "anosecurekit/aead.hpp"
#include "anosecurekit/error.hpp"
#include "fixture_utils.hpp"

namespace
{

anosecurekit::bytes bytes_from_ascii(std::string_view text)
{
	anosecurekit::bytes out;
	out.reserve(text.size());
	for (const char ch : text)
	{
		out.push_back(static_cast<std::byte>(static_cast<unsigned char>(ch)));
	}
	return out;
}

anosecurekit::key256 key_from_seed(unsigned int seed)
{
	anosecurekit::key256 key{};
	for (std::size_t i = 0; i < key.size(); ++i)
	{
		key[i] = static_cast<std::byte>((seed + i) & 0xffu);
	}
	return key;
}

template <typename Func>
void expect_error(Func &&func, anosecurekit::error_code expected)
{
	try
	{
		std::forward<Func>(func)();
		FAIL() << "expected anosecurekit::error";
	}
	catch (const anosecurekit::error &e)
	{
		EXPECT_EQ(e.code(), expected);
	}
}

} // namespace

TEST(KeyWrap, WrapsAndUnwrapsKeyWithSkt1Packet)
{
	const anosecurekit::key256 key_to_wrap = key_from_seed(0x10);
	const anosecurekit::key256 wrapping_key = key_from_seed(0x40);
	const anosecurekit::bytes aad = bytes_from_ascii("key-id:primary");

	const anosecurekit::bytes packet = anosecurekit::wrap_key(key_to_wrap, wrapping_key, aad);

	ASSERT_GE(packet.size(), 5u);
	EXPECT_EQ(packet[0], std::byte{'S'});
	EXPECT_EQ(packet[1], std::byte{'K'});
	EXPECT_EQ(packet[2], std::byte{'T'});
	EXPECT_EQ(packet[3], std::byte{'1'});
	EXPECT_EQ(packet[4], std::byte{0x01});
	EXPECT_EQ(anosecurekit::unwrap_key(packet, wrapping_key, aad), key_to_wrap);
}

TEST(KeyWrap, UnwrapsKnownSkt1KeyWrapFixture)
{
	const anosecurekit::key256 key_to_wrap = key_from_seed(0x10);
	const anosecurekit::key256 wrapping_key = key_from_seed(0x40);
	const anosecurekit::bytes aad = bytes_from_ascii("key-id:primary");
	const anosecurekit::bytes packet = anosecurekit::test::read_hex_fixture("skt1-key-wrap.hex");

	EXPECT_EQ(anosecurekit::unwrap_key(packet, wrapping_key, aad), key_to_wrap);
}

TEST(KeyWrap, UnwrapsKnownZeroKeyWrapFixture)
{
	const anosecurekit::key256 key_to_wrap{};
	const anosecurekit::key256 wrapping_key = key_from_seed(0x80);
	const anosecurekit::bytes packet = anosecurekit::test::read_hex_fixture("skt1-key-wrap-zero.hex");

	EXPECT_EQ(anosecurekit::unwrap_key(packet, wrapping_key), key_to_wrap);
}

TEST(KeyWrap, RejectsWrongWrappingKey)
{
	const anosecurekit::key256 key_to_wrap = key_from_seed(0x20);
	const anosecurekit::key256 wrapping_key = key_from_seed(0x50);
	const anosecurekit::key256 wrong_wrapping_key = key_from_seed(0x51);

	const anosecurekit::bytes packet = anosecurekit::wrap_key(key_to_wrap, wrapping_key);

	expect_error([&] { (void)anosecurekit::unwrap_key(packet, wrong_wrapping_key); }, anosecurekit::error_code::authentication_failed);
}

TEST(KeyWrap, RejectsWrongAad)
{
	const anosecurekit::key256 key_to_wrap = key_from_seed(0x30);
	const anosecurekit::key256 wrapping_key = key_from_seed(0x60);
	const anosecurekit::bytes aad = bytes_from_ascii("key-id:primary");
	const anosecurekit::bytes wrong_aad = bytes_from_ascii("key-id:secondary");

	const anosecurekit::bytes packet = anosecurekit::wrap_key(key_to_wrap, wrapping_key, aad);

	expect_error([&] { (void)anosecurekit::unwrap_key(packet, wrapping_key, wrong_aad); }, anosecurekit::error_code::authentication_failed);
}

TEST(KeyWrap, RejectsPacketsThatDoNotDecryptToOneKey)
{
	const anosecurekit::key256 wrapping_key = key_from_seed(0x70);
	const anosecurekit::bytes packet = anosecurekit::encrypt(bytes_from_ascii("short"), wrapping_key);

	expect_error([&] { (void)anosecurekit::unwrap_key(packet, wrapping_key); }, anosecurekit::error_code::invalid_packet);
}

TEST(KeyWrap, RejectsMalformedWrappedKeyPackets)
{
	const anosecurekit::key256 wrapping_key = key_from_seed(0x72);

	expect_error(
	    [&] { (void)anosecurekit::unwrap_key(anosecurekit::bytes{std::byte{'S'}, std::byte{'K'}, std::byte{'T'}}, wrapping_key); },
	    anosecurekit::error_code::invalid_packet);

	anosecurekit::bytes bad_version = anosecurekit::encrypt(bytes_from_ascii("short"), wrapping_key);
	bad_version[4] = std::byte{0x02};
	expect_error([&] { (void)anosecurekit::unwrap_key(bad_version, wrapping_key); }, anosecurekit::error_code::invalid_packet);
}

TEST(KeyWrap, RejectsPacketsThatDecryptToOversizedKey)
{
	const anosecurekit::key256 wrapping_key = key_from_seed(0x74);
	const anosecurekit::bytes long_plaintext(33, std::byte{0x42});
	const anosecurekit::bytes packet = anosecurekit::encrypt(long_plaintext, wrapping_key);

	expect_error([&] { (void)anosecurekit::unwrap_key(packet, wrapping_key); }, anosecurekit::error_code::invalid_packet);
}
