// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/aead.hpp"
#include "anosecurekit/anosecurekit.hpp"
#include "anosecurekit/base64.hpp"
#include "anosecurekit/compare.hpp"
#include "anosecurekit/error.hpp"
#include "anosecurekit/file.hpp"
#include "anosecurekit/hash.hpp"
#include "anosecurekit/hex.hpp"
#include "anosecurekit/key_wrap.hpp"
#include "anosecurekit/packet_stream.hpp"
#include "anosecurekit/random.hpp"
#include "anosecurekit/types.hpp"
#include "anosecurekit/version.hpp"

#include <filesystem>
#include <iosfwd>
#include <span>
#include <string>
#include <string_view>
#include <type_traits>

#include <gtest/gtest.h>

TEST(PublicHeaders, TypeAliasesAreAvailable)
{
	anosecurekit::bytes data;
	anosecurekit::key256 key{};
	anosecurekit::digest256 digest{};

	EXPECT_TRUE(data.empty());
	EXPECT_EQ(key.size(), 32u);
	EXPECT_EQ(digest.size(), 32u);
}

TEST(PublicHeaders, UtilityApiSignaturesAreAvailable)
{
	using StringFromBytesApi = std::string (*)(std::span<const std::byte>);
	using BytesFromStringApi = anosecurekit::bytes (*)(std::string_view);
	using DigestFromBytesApi = anosecurekit::digest256 (*)(std::span<const std::byte>);
	using HmacApi = anosecurekit::digest256 (*)(std::span<const std::byte>, std::span<const std::byte>);
	using HkdfApi = anosecurekit::bytes (*)(
	    std::span<const std::byte>,
	    std::span<const std::byte>,
	    std::span<const std::byte>,
	    std::size_t);
	using CompareApi = bool (*)(std::span<const std::byte>, std::span<const std::byte>);
	using RandomBytesApi = anosecurekit::bytes (*)(std::size_t);
	using GenerateKeyApi = anosecurekit::key256 (*)();
	using RandomTokenApi = std::string (*)(std::size_t);
	using AeadApi = anosecurekit::bytes (*)(
	    std::span<const std::byte>,
	    const anosecurekit::key256 &,
	    std::span<const std::byte>);

	static_assert(std::is_same_v<decltype(&anosecurekit::hex_encode), StringFromBytesApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::hex_decode), BytesFromStringApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::base64_encode), StringFromBytesApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::base64_decode), BytesFromStringApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::base64url_encode), StringFromBytesApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::base64url_decode), BytesFromStringApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::sha256), DigestFromBytesApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::hmac_sha256), HmacApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::hkdf_sha256), HkdfApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::constant_time_equal), CompareApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::random_bytes), RandomBytesApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::generate_key), GenerateKeyApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::random_token), RandomTokenApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::encrypt), AeadApi>);
	static_assert(std::is_same_v<decltype(&anosecurekit::decrypt), AeadApi>);
}

TEST(PublicHeaders, VersionApiIsAvailable)
{
	static_assert(std::is_same_v<decltype(&anosecurekit::version), std::string_view (*)() noexcept>);
	static_assert(std::is_same_v<decltype(&anosecurekit::version_major), int (*)() noexcept>);
	static_assert(std::is_same_v<decltype(&anosecurekit::version_minor), int (*)() noexcept>);
	static_assert(std::is_same_v<decltype(&anosecurekit::version_patch), int (*)() noexcept>);

	EXPECT_EQ(anosecurekit::version(), ANOSECUREKIT_EXPECTED_VERSION);
	EXPECT_EQ(anosecurekit::version_major(), ANOSECUREKIT_EXPECTED_VERSION_MAJOR);
	EXPECT_EQ(anosecurekit::version_minor(), ANOSECUREKIT_EXPECTED_VERSION_MINOR);
	EXPECT_EQ(anosecurekit::version_patch(), ANOSECUREKIT_EXPECTED_VERSION_PATCH);
}

TEST(PublicHeaders, ErrorApiIsAvailable)
{
	static_assert(std::is_constructible_v<anosecurekit::error, anosecurekit::error_code, std::string>);
	static_assert(std::is_same_v<
	    decltype(&anosecurekit::error::code),
	    anosecurekit::error_code (anosecurekit::error::*)() const noexcept>);
}

TEST(PublicHeaders, FileApiIsAvailable)
{
	using PathKeyFileApi = void (*)(const std::filesystem::path &, const std::filesystem::path &, const anosecurekit::key256 &, std::span<const std::byte>);
	using StreamKeyFileApi = void (*)(std::istream &, std::ostream &, const anosecurekit::key256 &, std::span<const std::byte>);
	using PathKeyVerifyApi = void (*)(const std::filesystem::path &, const anosecurekit::key256 &, std::span<const std::byte>);
	using StreamKeyVerifyApi = void (*)(std::istream &, const anosecurekit::key256 &, std::span<const std::byte>);
	using PathPasswordFileApi = void (*)(const std::filesystem::path &, const std::filesystem::path &, std::span<const std::byte>, std::span<const std::byte>);
	using StreamPasswordFileApi = void (*)(std::istream &, std::ostream &, std::span<const std::byte>, std::span<const std::byte>);
	using PathPasswordVerifyApi = void (*)(const std::filesystem::path &, std::span<const std::byte>, std::span<const std::byte>);
	using StreamPasswordVerifyApi = void (*)(std::istream &, std::span<const std::byte>, std::span<const std::byte>);

	static_assert(std::is_same_v<decltype(static_cast<PathKeyFileApi>(&anosecurekit::seal_file)), PathKeyFileApi>);
	static_assert(std::is_same_v<decltype(static_cast<PathKeyFileApi>(&anosecurekit::open_file)), PathKeyFileApi>);
	static_assert(std::is_same_v<decltype(static_cast<StreamKeyFileApi>(&anosecurekit::seal_file)), StreamKeyFileApi>);
	static_assert(std::is_same_v<decltype(static_cast<StreamKeyFileApi>(&anosecurekit::open_file)), StreamKeyFileApi>);
	static_assert(std::is_same_v<decltype(static_cast<PathKeyVerifyApi>(&anosecurekit::verify_file)), PathKeyVerifyApi>);
	static_assert(std::is_same_v<decltype(static_cast<StreamKeyVerifyApi>(&anosecurekit::verify_file)), StreamKeyVerifyApi>);
	static_assert(std::is_same_v<decltype(static_cast<PathPasswordFileApi>(&anosecurekit::seal_file_with_password)), PathPasswordFileApi>);
	static_assert(std::is_same_v<decltype(static_cast<PathPasswordFileApi>(&anosecurekit::open_file_with_password)), PathPasswordFileApi>);
	static_assert(std::is_same_v<decltype(static_cast<StreamPasswordFileApi>(&anosecurekit::seal_file_with_password)), StreamPasswordFileApi>);
	static_assert(std::is_same_v<decltype(static_cast<StreamPasswordFileApi>(&anosecurekit::open_file_with_password)), StreamPasswordFileApi>);
	static_assert(std::is_same_v<decltype(static_cast<PathPasswordVerifyApi>(&anosecurekit::verify_file_with_password)), PathPasswordVerifyApi>);
	static_assert(std::is_same_v<decltype(static_cast<StreamPasswordVerifyApi>(&anosecurekit::verify_file_with_password)), StreamPasswordVerifyApi>);
}

TEST(PublicHeaders, KeyWrapApiIsAvailable)
{
	static_assert(std::is_same_v<decltype(&anosecurekit::wrap_key), anosecurekit::bytes (*)(const anosecurekit::key256 &, const anosecurekit::key256 &, std::span<const std::byte>)>);
	static_assert(std::is_same_v<decltype(&anosecurekit::unwrap_key), anosecurekit::key256 (*)(std::span<const std::byte>, const anosecurekit::key256 &, std::span<const std::byte>)>);
}

TEST(PublicHeaders, PacketStreamApiIsAvailable)
{
	static_assert(!std::is_copy_constructible_v<anosecurekit::packet_encryptor>);
	static_assert(!std::is_copy_assignable_v<anosecurekit::packet_encryptor>);
	static_assert(std::is_move_constructible_v<anosecurekit::packet_encryptor>);
	static_assert(std::is_move_assignable_v<anosecurekit::packet_encryptor>);

	static_assert(!std::is_copy_constructible_v<anosecurekit::packet_decryptor>);
	static_assert(!std::is_copy_assignable_v<anosecurekit::packet_decryptor>);
	static_assert(std::is_move_constructible_v<anosecurekit::packet_decryptor>);
	static_assert(std::is_move_assignable_v<anosecurekit::packet_decryptor>);

	static_assert(std::is_same_v<decltype(&anosecurekit::packet_encryptor::begin), anosecurekit::bytes (anosecurekit::packet_encryptor::*)()>);
	static_assert(std::is_same_v<decltype(&anosecurekit::packet_encryptor::update),
	    anosecurekit::bytes (anosecurekit::packet_encryptor::*)(std::span<const std::byte>)>);
	static_assert(std::is_same_v<decltype(&anosecurekit::packet_encryptor::finalize), anosecurekit::bytes (anosecurekit::packet_encryptor::*)()>);

	static_assert(std::is_same_v<decltype(&anosecurekit::packet_decryptor::begin),
	    void (anosecurekit::packet_decryptor::*)(std::span<const std::byte>)>);
	static_assert(std::is_same_v<decltype(&anosecurekit::packet_decryptor::update),
	    anosecurekit::bytes (anosecurekit::packet_decryptor::*)(std::span<const std::byte>)>);
	static_assert(std::is_same_v<decltype(&anosecurekit::packet_decryptor::finalize),
	    anosecurekit::bytes (anosecurekit::packet_decryptor::*)(std::span<const std::byte>)>);
}
