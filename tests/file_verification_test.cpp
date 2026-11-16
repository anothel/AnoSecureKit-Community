// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/file.hpp"

#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>
#include <string_view>

#include <gtest/gtest.h>

#include "anosecurekit/error.hpp"
#include "anosecurekit/random.hpp"
#include "fixture_utils.hpp"

namespace
{
anosecurekit::bytes as_bytes(std::string_view text)
{
	return {reinterpret_cast<const std::byte *>(text.data()), reinterpret_cast<const std::byte *>(text.data() + text.size())};
}

struct private_directory
{
	std::filesystem::path path = std::filesystem::temp_directory_path() / ("anosecurekit-verify-" + anosecurekit::random_token(16));
	private_directory()
	{
		std::filesystem::create_directory(path);
	}
	~private_directory()
	{
		std::error_code ignored;
		std::filesystem::remove_all(path, ignored);
	}
};

void expect_failure(auto &&operation, anosecurekit::error_code code)
{
	try
	{
		operation();
		FAIL() << "verification accepted invalid input";
	}
	catch (const anosecurekit::error &e)
	{
		EXPECT_EQ(e.code(), code);
		if (code == anosecurekit::error_code::authentication_failed)
		{
			EXPECT_STREQ(e.what(), "File authentication failed");
		}
	}
}

void verify_both(std::string_view sealed, bool password_mode, std::span<const std::byte> aad,
    bool valid = true, anosecurekit::error_code code = anosecurekit::error_code::invalid_packet,
    const anosecurekit::key256 &key = {}, std::span<const std::byte> supplied_password = {})
{
	private_directory directory;
	const auto input_path = directory.path / "input";
	{
		std::ofstream out(input_path, std::ios::binary);
		out.write(sealed.data(), static_cast<std::streamsize>(sealed.size()));
		ASSERT_TRUE(out);
	}
	const auto default_password = as_bytes("known SKP1 password");
	const auto password = supplied_password.empty() ? std::span<const std::byte>(default_password) : supplied_password;
	std::istringstream stream{std::string(sealed), std::ios::binary};
	auto path_operation = [&] {
		if (password_mode)
			anosecurekit::verify_file_with_password(input_path, password, aad);
		else
			anosecurekit::verify_file(input_path, key, aad);
	};
	auto stream_operation = [&] {
		if (password_mode)
			anosecurekit::verify_file_with_password(stream, password, aad);
		else
			anosecurekit::verify_file(stream, key, aad);
	};
	if (valid)
	{
		EXPECT_NO_THROW(path_operation());
		EXPECT_NO_THROW(stream_operation());
		EXPECT_TRUE(stream.eof());
	}
	else
	{
		expect_failure(path_operation, code);
		expect_failure(stream_operation, code);
	}
	std::size_t count = 0;
	for (const auto &entry : std::filesystem::directory_iterator(directory.path))
	{
		EXPECT_EQ(entry.path(), input_path);
		++count;
	}
	EXPECT_EQ(count, 1u);
	std::ifstream unchanged(input_path, std::ios::binary);
	EXPECT_EQ(std::string(std::istreambuf_iterator<char>(unchanged), {}), sealed);
}
} // namespace

TEST(FileVerification, ConsumesEmptyExactAndMultipleChunksWithoutOutput)
{
	for (bool password_mode : {false, true})
	{
		for (std::size_t size : {0u, 1024u * 1024u, 1024u * 1024u + 17u})
		{
			SCOPED_TRACE(size);
			SCOPED_TRACE(password_mode);
			std::istringstream plain(std::string(size, 'p'), std::ios::binary);
			std::ostringstream sealed(std::ios::binary);
			const auto aad = as_bytes("fixture:aad");
			if (password_mode)
				anosecurekit::seal_file_with_password(plain, sealed, as_bytes("known SKP1 password"), aad);
			else
				anosecurekit::seal_file(plain, sealed, anosecurekit::key256{}, aad);
			verify_both(sealed.str(), password_mode, aad);
			if (size > 1024u * 1024u)
			{
				auto tampered = sealed.str();
				tampered.back() ^= 1;
				verify_both(tampered, password_mode, aad, false, anosecurekit::error_code::authentication_failed);
				auto truncated = sealed.str();
				truncated.pop_back();
				verify_both(truncated, password_mode, aad, false);
				verify_both(sealed.str() + 'x', password_mode, aad, false);
			}
		}
	}
}

TEST(FileVerification, AcceptsCompatibilityVectorsAndRejectsWrongCredentials)
{
	for (bool password_mode : {false, true})
	{
		const auto packet = anosecurekit::test::read_hex_fixture(password_mode ? "skp1-known-password-file.hex" : "skf1-known-file.hex");
		const std::string sealed(reinterpret_cast<const char *>(packet.data()), packet.size());
		verify_both(sealed, password_mode, as_bytes("fixture:aad"));
		verify_both(sealed, password_mode, as_bytes("wrong aad"), false, anosecurekit::error_code::authentication_failed);
		std::istringstream stream(sealed, std::ios::binary);
		anosecurekit::key256 wrong_key{};
		wrong_key[0] = std::byte{1};
		expect_failure([&] {
			if (password_mode)
				anosecurekit::verify_file_with_password(stream, as_bytes("wrong password"), as_bytes("fixture:aad"));
			else
				anosecurekit::verify_file(stream, wrong_key, as_bytes("fixture:aad"));
		},
		    anosecurekit::error_code::authentication_failed);
	}
}

TEST(FileVerification, RejectsEveryNegativeFileFixture)
{
	for (const auto &entry : std::filesystem::directory_iterator(std::filesystem::path(ANOSECUREKIT_TEST_FIXTURE_DIR) / "negative"))
	{
		const auto name = entry.path().filename().string();
		if (!name.starts_with("skf1-") && !name.starts_with("skp1-"))
			continue;
		SCOPED_TRACE(name);
		const auto packet = anosecurekit::test::read_hex_fixture("negative/" + name);
		verify_both(std::string(reinterpret_cast<const char *>(packet.data()), packet.size()), name.starts_with("skp1-"), as_bytes("fixture:aad"), false);
	}
}

TEST(FileVerification, PreservesInputErrorsAndRejectsEmptyPasswordsFirst)
{
	private_directory directory;
	const auto missing = directory.path / "missing";
	expect_failure([&] { anosecurekit::verify_file(missing, {}); }, anosecurekit::error_code::backend_failure);
	expect_failure([&] { anosecurekit::verify_file_with_password(missing, as_bytes("password")); }, anosecurekit::error_code::backend_failure);
	expect_failure([&] { anosecurekit::verify_file_with_password(missing, {}); }, anosecurekit::error_code::invalid_input);
	std::istringstream empty;
	expect_failure([&] { anosecurekit::verify_file_with_password(empty, {}); }, anosecurekit::error_code::invalid_input);
	EXPECT_EQ(empty.tellg(), 0);
	for (bool password_mode : {false, true})
	{
		std::istringstream stream;
		stream.setstate(std::ios::badbit);
		expect_failure([&] {
			if (password_mode)
				anosecurekit::verify_file_with_password(stream, as_bytes("password"));
			else
				anosecurekit::verify_file(stream, {});
		},
		    anosecurekit::error_code::backend_failure);
	}
}

TEST(FileVerification, AcceptsAllPositiveFixturesAndExactBinaryPasswords)
{
	struct vector
	{
		const char *name;
		const char *aad;
		const char *password;
		bool sequential_key;
	};
	for (const vector &v : {
	         vector{"skf1-known-file.hex", "fixture:aad", "", false},
	         vector{"skf1-empty-aad.hex", "fixture:empty", "", false},
	         vector{"skf1-binary-aad.hex", "fixture:binary", "", true},
	         vector{"skp1-known-password-file.hex", "fixture:aad", "known SKP1 password", false},
	         vector{"skp1-empty-aad.hex", "fixture:password:empty", "known SKP1 empty password", false},
	         vector{"skp1-binary-aad.hex", "fixture:password:binary", "known SKP1 binary password", false}})
	{
		SCOPED_TRACE(v.name);
		const auto packet = anosecurekit::test::read_hex_fixture(v.name);
		anosecurekit::key256 key{};
		if (v.sequential_key)
			for (std::size_t i = 0; i < key.size(); ++i)
				key[i] = static_cast<std::byte>(i);
		verify_both(std::string(reinterpret_cast<const char *>(packet.data()), packet.size()),
		    std::string_view(v.name).starts_with("skp1-"), as_bytes(v.aad), true,
		    anosecurekit::error_code::invalid_packet, key, as_bytes(v.password));
	}
	const auto password = as_bytes(std::string_view(" p\0w\n", 5));
	std::istringstream plain("binary password");
	std::ostringstream sealed(std::ios::binary);
	anosecurekit::seal_file_with_password(plain, sealed, password);
	verify_both(sealed.str(), true, {}, true, anosecurekit::error_code::invalid_packet, {}, password);
	verify_both(sealed.str(), true, {}, false, anosecurekit::error_code::authentication_failed, {}, as_bytes(" p"));
}
