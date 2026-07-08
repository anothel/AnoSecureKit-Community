// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/aead.hpp"

#include <cstddef>
#include <initializer_list>
#include <string_view>
#include <utility>

#include <gtest/gtest.h>

#include "anosecurekit/error.hpp"
#include "fixture_utils.hpp"

namespace
{

constexpr std::size_t kHeaderSize = 5;
constexpr std::size_t kNonceSize = 12;
constexpr std::size_t kTagSize = 16;
constexpr std::size_t kOverhead = kHeaderSize + kNonceSize + kTagSize;

anosecurekit::bytes bytes_from_ascii(std::string_view text)
{
	anosecurekit::bytes out;
	out.reserve(text.size());
	for (char ch : text)
	{
		out.push_back(static_cast<std::byte>(static_cast<unsigned char>(ch)));
	}
	return out;
}

anosecurekit::bytes bytes_from_values(std::initializer_list<unsigned int> values)
{
	anosecurekit::bytes out;
	out.reserve(values.size());
	for (unsigned int value : values)
	{
		out.push_back(static_cast<std::byte>(value));
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

template <typename Func>
void expect_invalid_packet(Func &&func)
{
	expect_error(std::forward<Func>(func), anosecurekit::error_code::invalid_packet);
}

template <typename Func>
void expect_authentication_failed(Func &&func)
{
	expect_error(std::forward<Func>(func), anosecurekit::error_code::authentication_failed);
}

template <typename Func>
void expect_generic_authentication_failure(Func &&func)
{
	try
	{
		std::forward<Func>(func)();
		FAIL() << "expected anosecurekit::error";
	}
	catch (const anosecurekit::error &e)
	{
		EXPECT_EQ(e.code(), anosecurekit::error_code::authentication_failed);
		EXPECT_STREQ(e.what(), "AEAD authentication failed");
	}
}

} // namespace

TEST(Aead, RoundTripsBinaryPlaintext)
{
	const anosecurekit::key256 key = key_from_seed(0x10);
	const anosecurekit::bytes plaintext = bytes_from_values({
	    0x00,
	    0x01,
	    0x02,
	    0x7f,
	    0x80,
	    0xff,
	    0x00,
	    0x42,
	});

	const anosecurekit::bytes packet = anosecurekit::encrypt(plaintext, key);

	ASSERT_EQ(packet.size(), plaintext.size() + kOverhead);
	EXPECT_EQ(packet[0], std::byte{'S'});
	EXPECT_EQ(packet[1], std::byte{'K'});
	EXPECT_EQ(packet[2], std::byte{'T'});
	EXPECT_EQ(packet[3], std::byte{'1'});
	EXPECT_EQ(packet[4], std::byte{0x01});
	EXPECT_EQ(anosecurekit::decrypt(packet, key), plaintext);
}

TEST(Aead, RoundTripsEmptyPlaintext)
{
	const anosecurekit::key256 key = key_from_seed(0x20);
	const anosecurekit::bytes plaintext;

	const anosecurekit::bytes packet = anosecurekit::encrypt(plaintext, key);

	EXPECT_EQ(packet.size(), kOverhead);
	EXPECT_TRUE(anosecurekit::decrypt(packet, key).empty());
}

TEST(Aead, RoundTripsLargePlaintextAndAad)
{
	const anosecurekit::key256 key = key_from_seed(0x22);
	anosecurekit::bytes plaintext(1024 * 1024);
	anosecurekit::bytes aad(64 * 1024);

	for (std::size_t i = 0; i < plaintext.size(); ++i)
	{
		plaintext[i] = static_cast<std::byte>((i * 31u) & 0xffu);
	}

	for (std::size_t i = 0; i < aad.size(); ++i)
	{
		aad[i] = static_cast<std::byte>((i * 17u) & 0xffu);
	}

	const anosecurekit::bytes packet = anosecurekit::encrypt(plaintext, key, aad);

	ASSERT_EQ(packet.size(), plaintext.size() + kOverhead);
	EXPECT_EQ(anosecurekit::decrypt(packet, key, aad), plaintext);
}

TEST(Aead, AuthenticatesAdditionalData)
{
	const anosecurekit::key256 key = key_from_seed(0x30);
	const anosecurekit::bytes plaintext = bytes_from_ascii("authenticated message");
	const anosecurekit::bytes aad = bytes_from_ascii("context");
	const anosecurekit::bytes wrong_aad = bytes_from_ascii("other context");

	const anosecurekit::bytes packet = anosecurekit::encrypt(plaintext, key, aad);

	EXPECT_EQ(anosecurekit::decrypt(packet, key, aad), plaintext);
	expect_authentication_failed([&] { (void)anosecurekit::decrypt(packet, key, wrong_aad); });
}

TEST(Aead, AuthenticationFailuresUseGenericMessage)
{
	const anosecurekit::key256 key = key_from_seed(0x70);
	const anosecurekit::key256 wrong_key = key_from_seed(0x71);
	const anosecurekit::bytes plaintext = bytes_from_ascii("secret");
	const anosecurekit::bytes aad = bytes_from_ascii("aad");
	const anosecurekit::bytes wrong_aad = bytes_from_ascii("other aad");

	const anosecurekit::bytes packet = anosecurekit::encrypt(plaintext, key, aad);

	anosecurekit::bytes bad_nonce = packet;
	bad_nonce[kHeaderSize] ^= std::byte{0x01};

	anosecurekit::bytes bad_ciphertext = packet;
	bad_ciphertext[kHeaderSize + kNonceSize] ^= std::byte{0x01};

	anosecurekit::bytes bad_tag = packet;
	bad_tag[bad_tag.size() - 1] ^= std::byte{0x01};

	expect_generic_authentication_failure([&] { (void)anosecurekit::decrypt(packet, key, wrong_aad); });
	expect_generic_authentication_failure([&] { (void)anosecurekit::decrypt(packet, wrong_key, aad); });
	expect_generic_authentication_failure([&] { (void)anosecurekit::decrypt(bad_nonce, key, aad); });
	expect_generic_authentication_failure([&] { (void)anosecurekit::decrypt(bad_ciphertext, key, aad); });
	expect_generic_authentication_failure([&] { (void)anosecurekit::decrypt(bad_tag, key, aad); });
}

TEST(Aead, DecryptsKnownAes256GcmPacketVector)
{
	const anosecurekit::key256 key{};
	const anosecurekit::bytes aad = bytes_from_ascii("record:v1");
	const anosecurekit::bytes expected_plaintext = bytes_from_ascii("hello anosecurekit");

	const anosecurekit::bytes packet = anosecurekit::test::read_hex_fixture("skt1-aes256-gcm-aad.hex");

	EXPECT_EQ(anosecurekit::decrypt(packet, key, aad), expected_plaintext);
}

TEST(Aead, DecryptsKnownEmptyAes256GcmPacketVector)
{
	const anosecurekit::key256 key{};

	const anosecurekit::bytes packet = anosecurekit::test::read_hex_fixture("skt1-aes256-gcm-empty.hex");

	EXPECT_TRUE(anosecurekit::decrypt(packet, key).empty());
}

TEST(Aead, DecryptsKnownBinaryAes256GcmPacketVectorWithAad)
{
	const anosecurekit::key256 key = key_from_seed(0x00);
	const anosecurekit::bytes aad = bytes_from_ascii("aad:extra");
	const anosecurekit::bytes expected_plaintext = bytes_from_values({
	    0x00,
	    0xff,
	    0x10,
	    0x20,
	    0x7f,
	    0x80,
	    0x41,
	    0x42,
	    0x43,
	});

	const anosecurekit::bytes packet = anosecurekit::test::read_hex_fixture("skt1-aes256-gcm-binary-aad.hex");

	EXPECT_EQ(anosecurekit::decrypt(packet, key, aad), expected_plaintext);
}

TEST(Aead, RejectsInvalidPacketShape)
{
	const anosecurekit::key256 key = key_from_seed(0x40);
	const anosecurekit::bytes plaintext = bytes_from_ascii("message");
	const anosecurekit::bytes packet = anosecurekit::encrypt(plaintext, key);

	expect_invalid_packet([&] { (void)anosecurekit::decrypt(anosecurekit::bytes(kOverhead - 1), key); });

	anosecurekit::bytes bad_magic = packet;
	bad_magic[0] = std::byte{'X'};
	expect_invalid_packet([&] { (void)anosecurekit::decrypt(bad_magic, key); });

	anosecurekit::bytes bad_version = packet;
	bad_version[4] = std::byte{0x02};
	expect_invalid_packet([&] { (void)anosecurekit::decrypt(bad_version, key); });
}

TEST(Aead, RejectsNegativeCompatibilityFixtureMissingTag)
{
	const anosecurekit::key256 key = key_from_seed(0x40);
	const anosecurekit::bytes packet = anosecurekit::test::read_hex_fixture("negative/skt1-missing-tag-format-minimum-size.hex");

	expect_invalid_packet([&] { (void)anosecurekit::decrypt(packet, key); });
}

TEST(Aead, RejectsNegativeCompatibilitySkt1HeaderRuleFixtures)
{
	const anosecurekit::key256 key = key_from_seed(0x40);
	for (const std::string_view fixture_name : {
	         "negative/skt1-bad-magic.hex",
	         "negative/skt1-unsupported-version.hex",
	     })
	{
		SCOPED_TRACE(fixture_name);
		const anosecurekit::bytes packet = anosecurekit::test::read_hex_fixture(fixture_name);
		expect_invalid_packet([&] { (void)anosecurekit::decrypt(packet, key); });
	}
}

TEST(Aead, DetectsPacketMutation)
{
	const anosecurekit::key256 key = key_from_seed(0x50);
	const anosecurekit::bytes plaintext = bytes_from_ascii("mutable ciphertext");
	const anosecurekit::bytes aad = bytes_from_ascii("aad");
	const anosecurekit::bytes packet = anosecurekit::encrypt(plaintext, key, aad);

	anosecurekit::bytes bad_nonce = packet;
	bad_nonce[kHeaderSize] ^= std::byte{0x01};
	expect_authentication_failed([&] { (void)anosecurekit::decrypt(bad_nonce, key, aad); });

	anosecurekit::bytes bad_ciphertext = packet;
	bad_ciphertext[kHeaderSize + kNonceSize] ^= std::byte{0x01};
	expect_authentication_failed([&] { (void)anosecurekit::decrypt(bad_ciphertext, key, aad); });

	anosecurekit::bytes bad_tag = packet;
	bad_tag[bad_tag.size() - 1] ^= std::byte{0x01};
	expect_authentication_failed([&] { (void)anosecurekit::decrypt(bad_tag, key, aad); });
}

TEST(Aead, RejectsWrongKey)
{
	const anosecurekit::key256 key = key_from_seed(0x60);
	const anosecurekit::key256 wrong_key = key_from_seed(0x61);
	const anosecurekit::bytes plaintext = bytes_from_ascii("secret");

	const anosecurekit::bytes packet = anosecurekit::encrypt(plaintext, key);

	expect_authentication_failed([&] { (void)anosecurekit::decrypt(packet, wrong_key); });
}
