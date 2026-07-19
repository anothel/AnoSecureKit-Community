// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/file.hpp"

#include <algorithm>
#include <cstddef>
#include <filesystem>
#include <fstream>
#include <initializer_list>
#include <iterator>
#include <sstream>
#include <string>
#include <string_view>
#include <utility>

#include <gtest/gtest.h>

#include "anosecurekit/error.hpp"
#include "fixture_utils.hpp"

namespace
{

anosecurekit::key256 key_from_seed(unsigned int seed)
{
	anosecurekit::key256 key{};
	for (std::size_t i = 0; i < key.size(); ++i)
	{
		key[i] = static_cast<std::byte>((seed + i) & 0xffu);
	}
	return key;
}

std::filesystem::path test_path(const std::string &name)
{
	return std::filesystem::temp_directory_path() / ("anosecurekit-" + name);
}

std::filesystem::path temp_path_for(const std::filesystem::path &output)
{
	std::filesystem::path temp = output;
	temp += ".anosecurekit.tmp";
	return temp;
}

std::string anosecurekit_temp_prefix_for(const std::filesystem::path &output)
{
	return output.filename().string() + ".anosecurekit.";
}

bool is_anosecurekit_temp_output_for(const std::filesystem::path &candidate, const std::filesystem::path &output)
{
	const std::string name = candidate.filename().string();
	const std::string prefix = anosecurekit_temp_prefix_for(output);
	const std::string suffix = ".tmp";
	return name.rfind(prefix, 0) == 0 && name.size() >= suffix.size() &&
	       name.compare(name.size() - suffix.size(), suffix.size(), suffix) == 0;
}

void remove_anosecurekit_temp_outputs_for(const std::filesystem::path &output)
{
	const std::filesystem::path directory = output.parent_path();
	if (directory.empty() || !std::filesystem::exists(directory))
	{
		return;
	}

	for (const std::filesystem::directory_entry &entry : std::filesystem::directory_iterator(directory))
	{
		if (entry.is_regular_file() && is_anosecurekit_temp_output_for(entry.path(), output))
		{
			std::filesystem::remove(entry.path());
		}
	}
}

bool has_anosecurekit_temp_output_for(const std::filesystem::path &output)
{
	const std::filesystem::path directory = output.parent_path();
	if (directory.empty() || !std::filesystem::exists(directory))
	{
		return false;
	}

	for (const std::filesystem::directory_entry &entry : std::filesystem::directory_iterator(directory))
	{
		if (entry.is_regular_file() && is_anosecurekit_temp_output_for(entry.path(), output))
		{
			return true;
		}
	}
	return false;
}

void write_file(const std::filesystem::path &path, const anosecurekit::bytes &bytes)
{
	std::ofstream out(path, std::ios::binary | std::ios::trunc);
	ASSERT_TRUE(out);
	out.write(reinterpret_cast<const char *>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
	ASSERT_TRUE(out);
}

anosecurekit::bytes read_file(const std::filesystem::path &path)
{
	std::ifstream in(path, std::ios::binary);
	EXPECT_TRUE(in);
	const std::string data{std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>()};
	anosecurekit::bytes out;
	out.reserve(data.size());
	for (const unsigned char ch : data)
	{
		out.push_back(static_cast<std::byte>(ch));
	}
	return out;
}

anosecurekit::bytes bytes_from_text(std::string_view text)
{
	anosecurekit::bytes out;
	out.reserve(text.size());
	for (const unsigned char ch : text)
	{
		out.push_back(static_cast<std::byte>(ch));
	}
	return out;
}

anosecurekit::bytes bytes_from_values(std::initializer_list<unsigned int> values)
{
	anosecurekit::bytes out;
	out.reserve(values.size());
	for (const unsigned int value : values)
	{
		out.push_back(static_cast<std::byte>(value));
	}
	return out;
}

std::string string_from_bytes(const anosecurekit::bytes &bytes)
{
	std::string out;
	out.reserve(bytes.size());
	for (const std::byte byte : bytes)
	{
		out.push_back(static_cast<char>(std::to_integer<unsigned char>(byte)));
	}
	return out;
}

anosecurekit::bytes patterned_bytes(std::size_t size, unsigned int multiplier)
{
	anosecurekit::bytes out(size);
	for (std::size_t i = 0; i < out.size(); ++i)
	{
		out[i] = static_cast<std::byte>((i * multiplier) & 0xffu);
	}
	return out;
}

template <typename Func>
void expect_error(Func &&func, anosecurekit::error_code expected)
{
	try
	{
		std::forward<Func>(func)();
		FAIL() << "expected anosecurekit::error";
	}
	catch (const anosecurekit::error &ex)
	{
		EXPECT_EQ(ex.code(), expected);
	}
}

void expect_authentication_failed(auto &&func)
{
	expect_error(std::forward<decltype(func)>(func), anosecurekit::error_code::authentication_failed);
}

void expect_generic_authentication_failure(auto &&func)
{
	try
	{
		std::forward<decltype(func)>(func)();
		FAIL() << "expected anosecurekit::error";
	}
	catch (const anosecurekit::error &ex)
	{
		EXPECT_EQ(ex.code(), anosecurekit::error_code::authentication_failed);
		EXPECT_STREQ(ex.what(), "File authentication failed");
	}
}

void expect_invalid_packet(auto &&func)
{
	expect_error(std::forward<decltype(func)>(func), anosecurekit::error_code::invalid_packet);
}

} // namespace

TEST(File, RoundTripsSmallFile)
{
	const auto plain_path = test_path("plain-small.bin");
	const auto sealed_path = test_path("sealed-small.skf");
	const auto opened_path = test_path("opened-small.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes plaintext = bytes_from_text("hello file sealing");
	const anosecurekit::bytes aad = bytes_from_text("file:test");
	const anosecurekit::key256 key = key_from_seed(0x10);
	write_file(plain_path, plaintext);

	anosecurekit::seal_file(plain_path, sealed_path, key, aad);
	const anosecurekit::bytes sealed = read_file(sealed_path);
	ASSERT_GE(sealed.size(), 4u + 1u + 1u + 4u + 32u + 8u + 4u + 4u + 1u + 16u);
	EXPECT_EQ(sealed[0], std::byte{'S'});
	EXPECT_EQ(sealed[1], std::byte{'K'});
	EXPECT_EQ(sealed[2], std::byte{'F'});
	EXPECT_EQ(sealed[3], std::byte{'1'});
	EXPECT_EQ(sealed[4], std::byte{0x01});
	EXPECT_EQ(sealed[5], std::byte{0x01});

	anosecurekit::open_file(sealed_path, opened_path, key, aad);

	EXPECT_EQ(read_file(opened_path), plaintext);
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, RoundTripsEmptyFile)
{
	const auto plain_path = test_path("plain-empty.bin");
	const auto sealed_path = test_path("sealed-empty.skf");
	const auto opened_path = test_path("opened-empty.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::key256 key = key_from_seed(0x21);
	write_file(plain_path, {});
	anosecurekit::seal_file(plain_path, sealed_path, key);
	anosecurekit::open_file(sealed_path, opened_path, key);
	EXPECT_TRUE(read_file(opened_path).empty());

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, RoundTripsStreams)
{
	const anosecurekit::bytes plaintext = patterned_bytes((1024u * 1024u) + 31u, 11u);
	const anosecurekit::bytes aad = bytes_from_text("stream:file:test");
	const anosecurekit::key256 key = key_from_seed(0x22);

	std::istringstream plain_stream(string_from_bytes(plaintext), std::ios::binary);
	std::ostringstream sealed_stream(std::ios::binary);
	anosecurekit::seal_file(plain_stream, sealed_stream, key, aad);

	const anosecurekit::bytes sealed = bytes_from_text(sealed_stream.str());
	ASSERT_GE(sealed.size(), 50u + 9u + plaintext.size() + 16u);
	EXPECT_EQ(sealed[0], std::byte{'S'});
	EXPECT_EQ(sealed[1], std::byte{'K'});
	EXPECT_EQ(sealed[2], std::byte{'F'});
	EXPECT_EQ(sealed[3], std::byte{'1'});

	std::istringstream sealed_input(sealed_stream.str(), std::ios::binary);
	std::ostringstream opened_stream(std::ios::binary);
	anosecurekit::open_file(sealed_input, opened_stream, key, aad);

	EXPECT_EQ(bytes_from_text(opened_stream.str()), plaintext);
}

TEST(File, StreamRejectsTrailingDataBeforeWritingFinalPlaintext)
{
	const anosecurekit::bytes plaintext = bytes_from_text("stream trailing plaintext");
	const anosecurekit::key256 key = key_from_seed(0x24);

	std::istringstream plain_stream(string_from_bytes(plaintext), std::ios::binary);
	std::ostringstream sealed_stream(std::ios::binary);
	anosecurekit::seal_file(plain_stream, sealed_stream, key);

	std::string sealed = sealed_stream.str();
	sealed.push_back('\0');

	std::istringstream sealed_input(sealed, std::ios::binary);
	std::ostringstream opened_stream(std::ios::binary);
	expect_invalid_packet([&] { anosecurekit::open_file(sealed_input, opened_stream, key); });
	EXPECT_TRUE(opened_stream.str().empty());
}

TEST(File, StreamFailuresUseBackendError)
{
	const anosecurekit::bytes plaintext = bytes_from_text("stream failure plaintext");
	const anosecurekit::bytes aad = bytes_from_text("stream:failure");
	const anosecurekit::bytes password = bytes_from_text("stream failure password");
	const anosecurekit::key256 key = key_from_seed(0x23);

	std::istringstream plain_stream(string_from_bytes(plaintext), std::ios::binary);
	std::ostringstream sealed_stream(std::ios::binary);
	anosecurekit::seal_file(plain_stream, sealed_stream, key, aad);

	std::istringstream password_plain_stream(string_from_bytes(plaintext), std::ios::binary);
	std::ostringstream password_sealed_stream(std::ios::binary);
	anosecurekit::seal_file_with_password(password_plain_stream, password_sealed_stream, password, aad);

	std::istringstream failed_plain_input(string_from_bytes(plaintext), std::ios::binary);
	failed_plain_input.setstate(std::ios::badbit);
	expect_error(
	    [&] {
		    std::ostringstream output(std::ios::binary);
		    anosecurekit::seal_file(failed_plain_input, output, key, aad);
	    },
	    anosecurekit::error_code::backend_failure);

	std::istringstream failed_password_plain_input(string_from_bytes(plaintext), std::ios::binary);
	failed_password_plain_input.setstate(std::ios::badbit);
	expect_error(
	    [&] {
		    std::ostringstream output(std::ios::binary);
		    anosecurekit::seal_file_with_password(failed_password_plain_input, output, password, aad);
	    },
	    anosecurekit::error_code::backend_failure);

	std::istringstream failed_sealed_input(sealed_stream.str(), std::ios::binary);
	failed_sealed_input.setstate(std::ios::badbit);
	expect_error(
	    [&] {
		    std::ostringstream output(std::ios::binary);
		    anosecurekit::open_file(failed_sealed_input, output, key, aad);
	    },
	    anosecurekit::error_code::backend_failure);

	std::istringstream failed_password_sealed_input(password_sealed_stream.str(), std::ios::binary);
	failed_password_sealed_input.setstate(std::ios::badbit);
	expect_error(
	    [&] {
		    std::ostringstream output(std::ios::binary);
		    anosecurekit::open_file_with_password(failed_password_sealed_input, output, password, aad);
	    },
	    anosecurekit::error_code::backend_failure);
}

TEST(File, OpensKnownSkf1Fixture)
{
	const auto sealed_path = test_path("known-fixture.skf");
	const auto opened_path = test_path("known-fixture-opened.bin");
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::key256 key{};
	const anosecurekit::bytes aad = bytes_from_text("fixture:aad");
	const anosecurekit::bytes fixture = anosecurekit::test::read_hex_fixture("skf1-known-file.hex");

	write_file(sealed_path, fixture);
	anosecurekit::open_file(sealed_path, opened_path, key, aad);

	EXPECT_EQ(read_file(opened_path), bytes_from_text("known SKF1 vector"));

	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, OpensKnownSkf1EmptyFixture)
{
	const auto sealed_path = test_path("known-empty-fixture.skf");
	const auto opened_path = test_path("known-empty-fixture-opened.bin");
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::key256 key{};
	const anosecurekit::bytes aad = bytes_from_text("fixture:empty");
	const anosecurekit::bytes fixture = anosecurekit::test::read_hex_fixture("skf1-empty-aad.hex");

	write_file(sealed_path, fixture);
	anosecurekit::open_file(sealed_path, opened_path, key, aad);

	EXPECT_TRUE(read_file(opened_path).empty());

	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, OpensKnownSkf1BinaryFixtureWithAad)
{
	const auto sealed_path = test_path("known-binary-fixture.skf");
	const auto opened_path = test_path("known-binary-fixture-opened.bin");
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::key256 key = key_from_seed(0x00);
	const anosecurekit::bytes aad = bytes_from_text("fixture:binary");
	const anosecurekit::bytes fixture = anosecurekit::test::read_hex_fixture("skf1-binary-aad.hex");

	write_file(sealed_path, fixture);
	anosecurekit::open_file(sealed_path, opened_path, key, aad);

	EXPECT_EQ(read_file(opened_path), bytes_from_values({0x00, 0xff, 0x10, 0x20, 0x7f, 0x80, 0x41, 0x42, 0x43}));

	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, OpensKnownSkp1Fixture)
{
	const auto sealed_path = test_path("known-password-fixture.skp");
	const auto opened_path = test_path("known-password-fixture-opened.bin");
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes password = bytes_from_text("known SKP1 password");
	const anosecurekit::bytes aad = bytes_from_text("fixture:aad");
	const anosecurekit::bytes fixture = anosecurekit::test::read_hex_fixture("skp1-known-password-file.hex");

	write_file(sealed_path, fixture);
	anosecurekit::open_file_with_password(sealed_path, opened_path, password, aad);

	EXPECT_EQ(read_file(opened_path), bytes_from_text("known SKP1 vector"));

	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, OpensKnownSkp1EmptyFixtureWithAad)
{
	const auto sealed_path = test_path("known-password-empty-fixture.skp");
	const auto opened_path = test_path("known-password-empty-fixture-opened.bin");
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes password = bytes_from_text("known SKP1 empty password");
	const anosecurekit::bytes aad = bytes_from_text("fixture:password:empty");
	const anosecurekit::bytes fixture = anosecurekit::test::read_hex_fixture("skp1-empty-aad.hex");

	write_file(sealed_path, fixture);
	anosecurekit::open_file_with_password(sealed_path, opened_path, password, aad);

	EXPECT_TRUE(read_file(opened_path).empty());

	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, OpensKnownSkp1BinaryFixtureWithAad)
{
	const auto sealed_path = test_path("known-password-binary-fixture.skp");
	const auto opened_path = test_path("known-password-binary-fixture-opened.bin");
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes password = bytes_from_text("known SKP1 binary password");
	const anosecurekit::bytes aad = bytes_from_text("fixture:password:binary");
	const anosecurekit::bytes fixture = anosecurekit::test::read_hex_fixture("skp1-binary-aad.hex");

	write_file(sealed_path, fixture);
	anosecurekit::open_file_with_password(sealed_path, opened_path, password, aad);

	EXPECT_EQ(read_file(opened_path), bytes_from_values({0x00, 0x01, 0xfe, 0xff, 0x42, 0x00, 0x7f, 0x80}));

	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, RejectsExistingOutput)
{
	const auto plain_path = test_path("plain-output-exists.bin");
	const auto sealed_path = test_path("sealed-output-exists.skf");
	const auto opened_path = test_path("opened-output-exists.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::key256 key = key_from_seed(0x30);
	write_file(plain_path, bytes_from_text("input"));
	write_file(sealed_path, bytes_from_text("existing"));

	expect_error([&] { anosecurekit::seal_file(plain_path, sealed_path, key); }, anosecurekit::error_code::invalid_input);
	EXPECT_EQ(read_file(sealed_path), bytes_from_text("existing"));

	std::filesystem::remove(sealed_path);
	anosecurekit::seal_file(plain_path, sealed_path, key);
	write_file(opened_path, bytes_from_text("existing output"));
	expect_error([&] { anosecurekit::open_file(sealed_path, opened_path, key); }, anosecurekit::error_code::invalid_input);
	EXPECT_EQ(read_file(opened_path), bytes_from_text("existing output"));

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, RejectsMissingInputAndRemovesTemporaryOutput)
{
	const auto missing_plain_path = test_path("plain-missing-input.bin");
	const auto missing_sealed_path = test_path("sealed-missing-input.skf");
	const auto sealed_output_path = test_path("sealed-missing-output.skf");
	const auto opened_output_path = test_path("opened-missing-output.bin");
	const auto password_output_path = test_path("password-sealed-missing-output.skp");
	const auto password_opened_output_path = test_path("password-opened-missing-output.bin");
	std::filesystem::remove(missing_plain_path);
	std::filesystem::remove(missing_sealed_path);
	std::filesystem::remove(sealed_output_path);
	std::filesystem::remove(opened_output_path);
	std::filesystem::remove(password_output_path);
	std::filesystem::remove(password_opened_output_path);
	remove_anosecurekit_temp_outputs_for(sealed_output_path);
	remove_anosecurekit_temp_outputs_for(opened_output_path);
	remove_anosecurekit_temp_outputs_for(password_output_path);
	remove_anosecurekit_temp_outputs_for(password_opened_output_path);

	const anosecurekit::key256 key = key_from_seed(0x32);
	const anosecurekit::bytes password = bytes_from_text("missing input password");

	expect_error([&] { anosecurekit::seal_file(missing_plain_path, sealed_output_path, key); }, anosecurekit::error_code::backend_failure);
	EXPECT_FALSE(std::filesystem::exists(sealed_output_path));
	EXPECT_FALSE(has_anosecurekit_temp_output_for(sealed_output_path));

	expect_error([&] { anosecurekit::open_file(missing_sealed_path, opened_output_path, key); }, anosecurekit::error_code::backend_failure);
	EXPECT_FALSE(std::filesystem::exists(opened_output_path));
	EXPECT_FALSE(has_anosecurekit_temp_output_for(opened_output_path));

	expect_error(
	    [&] { anosecurekit::seal_file_with_password(missing_plain_path, password_output_path, password); },
	    anosecurekit::error_code::backend_failure);
	EXPECT_FALSE(std::filesystem::exists(password_output_path));
	EXPECT_FALSE(has_anosecurekit_temp_output_for(password_output_path));

	expect_error(
	    [&] { anosecurekit::open_file_with_password(missing_sealed_path, password_opened_output_path, password); },
	    anosecurekit::error_code::backend_failure);
	EXPECT_FALSE(std::filesystem::exists(password_opened_output_path));
	EXPECT_FALSE(has_anosecurekit_temp_output_for(password_opened_output_path));

	std::filesystem::remove(sealed_output_path);
	std::filesystem::remove(opened_output_path);
	std::filesystem::remove(password_output_path);
	std::filesystem::remove(password_opened_output_path);
	remove_anosecurekit_temp_outputs_for(sealed_output_path);
	remove_anosecurekit_temp_outputs_for(opened_output_path);
	remove_anosecurekit_temp_outputs_for(password_output_path);
	remove_anosecurekit_temp_outputs_for(password_opened_output_path);
}

TEST(File, UsesUniqueTemporaryOutput)
{
	const auto plain_path = test_path("plain-temp-collision.bin");
	const auto sealed_path = test_path("sealed-temp-collision.skf");
	const auto opened_path = test_path("opened-temp-collision.bin");
	const auto sealed_temp_path = temp_path_for(sealed_path);
	const auto opened_temp_path = temp_path_for(opened_path);
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	std::filesystem::remove(sealed_temp_path);
	std::filesystem::remove(opened_temp_path);

	const anosecurekit::key256 key = key_from_seed(0x33);
	const anosecurekit::bytes existing_temp = bytes_from_text("existing temp");
	const anosecurekit::bytes plaintext = bytes_from_text("temp collision plaintext");
	write_file(plain_path, plaintext);
	write_file(sealed_temp_path, existing_temp);

	anosecurekit::seal_file(plain_path, sealed_path, key);
	EXPECT_TRUE(std::filesystem::exists(sealed_path));
	EXPECT_EQ(read_file(sealed_temp_path), existing_temp);

	write_file(opened_temp_path, existing_temp);

	anosecurekit::open_file(sealed_path, opened_path, key);
	EXPECT_EQ(read_file(opened_path), plaintext);
	EXPECT_EQ(read_file(opened_temp_path), existing_temp);

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	std::filesystem::remove(sealed_temp_path);
	std::filesystem::remove(opened_temp_path);
}

TEST(File, RejectsMalformedHeader)
{
	const auto plain_path = test_path("plain-malformed-header.bin");
	const auto sealed_path = test_path("sealed-malformed-header.skf");
	const auto opened_path = test_path("opened-malformed-header.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::key256 key = key_from_seed(0x31);
	write_file(plain_path, bytes_from_text("header"));
	anosecurekit::seal_file(plain_path, sealed_path, key);

	for (const std::size_t offset : {0u, 1u, 2u, 3u, 4u, 5u, 6u, 9u})
	{
		anosecurekit::bytes sealed = read_file(sealed_path);
		sealed[offset] ^= std::byte{0x01};
		write_file(sealed_path, sealed);
		expect_error([&] { anosecurekit::open_file(sealed_path, opened_path, key); }, anosecurekit::error_code::invalid_packet);
		std::filesystem::remove(opened_path);
	}

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, RejectsWrongKeyAndAad)
{
	const auto plain_path = test_path("plain-wrong-key.bin");
	const auto sealed_path = test_path("sealed-wrong-key.skf");
	const auto opened_path = test_path("opened-wrong-key.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::key256 key = key_from_seed(0x40);
	const anosecurekit::key256 wrong_key = key_from_seed(0x41);
	const anosecurekit::bytes aad = bytes_from_text("aad");
	write_file(plain_path, bytes_from_text("secret"));
	anosecurekit::seal_file(plain_path, sealed_path, key, aad);

	expect_authentication_failed([&] { anosecurekit::open_file(sealed_path, opened_path, wrong_key, aad); });
	expect_authentication_failed([&] { anosecurekit::open_file(sealed_path, opened_path, key, bytes_from_text("wrong aad")); });

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, AuthenticationFailuresUseGenericMessage)
{
	const auto plain_path = test_path("plain-generic-auth.bin");
	const auto sealed_path = test_path("sealed-generic-auth.skf");
	const auto opened_path = test_path("opened-generic-auth.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::key256 key = key_from_seed(0x42);
	const anosecurekit::key256 wrong_key = key_from_seed(0x43);
	const anosecurekit::bytes aad = bytes_from_text("aad");
	write_file(plain_path, bytes_from_text("secret"));
	anosecurekit::seal_file(plain_path, sealed_path, key, aad);

	const anosecurekit::bytes original = read_file(sealed_path);
	const std::size_t ciphertext_offset = 50u + 9u;
	const std::size_t tag_offset = original.size() - 16u;

	anosecurekit::bytes bad_ciphertext = original;
	bad_ciphertext[ciphertext_offset] ^= std::byte{0x01};

	anosecurekit::bytes bad_tag = original;
	bad_tag[tag_offset] ^= std::byte{0x01};

	expect_generic_authentication_failure([&] { anosecurekit::open_file(sealed_path, opened_path, wrong_key, aad); });
	expect_generic_authentication_failure([&] { anosecurekit::open_file(sealed_path, opened_path, key, bytes_from_text("wrong aad")); });

	write_file(sealed_path, bad_ciphertext);
	expect_generic_authentication_failure([&] { anosecurekit::open_file(sealed_path, opened_path, key, aad); });

	write_file(sealed_path, bad_tag);
	expect_generic_authentication_failure([&] { anosecurekit::open_file(sealed_path, opened_path, key, aad); });

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, RemovesTemporaryOutputAfterOpenFailure)
{
	const auto plain_path = test_path("plain-open-failure-cleanup.bin");
	const auto sealed_path = test_path("sealed-open-failure-cleanup.skf");
	const auto opened_path = test_path("opened-open-failure-cleanup.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	remove_anosecurekit_temp_outputs_for(opened_path);

	const anosecurekit::key256 key = key_from_seed(0x44);
	const anosecurekit::key256 wrong_key = key_from_seed(0x45);
	write_file(plain_path, bytes_from_text("cleanup on failure"));
	anosecurekit::seal_file(plain_path, sealed_path, key);

	expect_generic_authentication_failure([&] { anosecurekit::open_file(sealed_path, opened_path, wrong_key); });

	EXPECT_FALSE(std::filesystem::exists(opened_path));
	EXPECT_FALSE(has_anosecurekit_temp_output_for(opened_path));

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	remove_anosecurekit_temp_outputs_for(opened_path);
}

TEST(File, RemovesPartialTemporaryOutputAfterLateOpenFailure)
{
	const auto plain_path = test_path("plain-late-open-failure-cleanup.bin");
	const auto sealed_path = test_path("sealed-late-open-failure-cleanup.skf");
	const auto opened_path = test_path("opened-late-open-failure-cleanup.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	remove_anosecurekit_temp_outputs_for(opened_path);

	const anosecurekit::key256 key = key_from_seed(0x46);
	anosecurekit::bytes plaintext((1024u * 1024u) + 17u);
	for (std::size_t i = 0; i < plaintext.size(); ++i)
	{
		plaintext[i] = static_cast<std::byte>((i * 37u) & 0xffu);
	}
	write_file(plain_path, plaintext);
	anosecurekit::seal_file(plain_path, sealed_path, key);

	anosecurekit::bytes sealed = read_file(sealed_path);
	sealed.back() ^= std::byte{0x01};
	write_file(sealed_path, sealed);

	expect_generic_authentication_failure([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	EXPECT_FALSE(std::filesystem::exists(opened_path));
	EXPECT_FALSE(has_anosecurekit_temp_output_for(opened_path));

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	remove_anosecurekit_temp_outputs_for(opened_path);
}

TEST(File, DetectsMutation)
{
	const auto plain_path = test_path("plain-mutation.bin");
	const auto sealed_path = test_path("sealed-mutation.skf");
	const auto opened_path = test_path("opened-mutation.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::key256 key = key_from_seed(0x50);
	write_file(plain_path, bytes_from_text("mutable"));
	anosecurekit::seal_file(plain_path, sealed_path, key);
	const anosecurekit::bytes original = read_file(sealed_path);

	const std::size_t header_size = 50;
	const std::size_t record_size_offset = header_size + 4;
	const std::size_t record_flag_offset = header_size + 8;
	const std::size_t ciphertext_offset = header_size + 9;
	const std::size_t tag_offset = original.size() - 16;

	anosecurekit::bytes mutated_header = original;
	mutated_header[10] ^= std::byte{0x01};
	write_file(sealed_path, mutated_header);
	expect_authentication_failed([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	anosecurekit::bytes mutated_size = original;
	mutated_size[record_size_offset + 3] ^= std::byte{0x01};
	write_file(sealed_path, mutated_size);
	expect_invalid_packet([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	anosecurekit::bytes mutated_flag = original;
	mutated_flag[record_flag_offset] = std::byte{0x00};
	write_file(sealed_path, mutated_flag);
	expect_invalid_packet([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	anosecurekit::bytes mutated_ciphertext = original;
	mutated_ciphertext[ciphertext_offset] ^= std::byte{0x01};
	write_file(sealed_path, mutated_ciphertext);
	expect_authentication_failed([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	anosecurekit::bytes mutated_tag = original;
	mutated_tag[tag_offset] ^= std::byte{0x01};
	write_file(sealed_path, mutated_tag);
	expect_authentication_failed([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, DetectsTruncationAppendAndReorder)
{
	const auto plain_path = test_path("plain-shape.bin");
	const auto sealed_path = test_path("sealed-shape.skf");
	const auto opened_path = test_path("opened-shape.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	anosecurekit::bytes plaintext((1024u * 1024u * 2u) + 17u);
	for (std::size_t i = 0; i < plaintext.size(); ++i)
	{
		plaintext[i] = static_cast<std::byte>((i * 13u) & 0xffu);
	}

	const anosecurekit::key256 key = key_from_seed(0x60);
	write_file(plain_path, plaintext);
	anosecurekit::seal_file(plain_path, sealed_path, key);
	const anosecurekit::bytes original = read_file(sealed_path);

	anosecurekit::bytes truncated = original;
	truncated.pop_back();
	write_file(sealed_path, truncated);
	expect_invalid_packet([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	anosecurekit::bytes appended = original;
	appended.push_back(std::byte{0x00});
	write_file(sealed_path, appended);
	expect_invalid_packet([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	const std::size_t header_size = 50;
	const std::size_t full_record_size = 9 + (1024u * 1024u) + 16;
	anosecurekit::bytes reordered = original;
	std::swap_ranges(
	    reordered.begin() + static_cast<std::ptrdiff_t>(header_size),
	    reordered.begin() + static_cast<std::ptrdiff_t>(header_size + full_record_size),
	    reordered.begin() + static_cast<std::ptrdiff_t>(header_size + full_record_size));
	write_file(sealed_path, reordered);
	expect_invalid_packet([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	anosecurekit::bytes duplicate_index = original;
	std::fill_n(duplicate_index.begin() + static_cast<std::ptrdiff_t>(header_size + full_record_size), 4, std::byte{0x00});
	write_file(sealed_path, duplicate_index);
	expect_invalid_packet([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, RejectsMalformedRecordShape)
{
	const auto plain_path = test_path("plain-record-shape.bin");
	const auto sealed_path = test_path("sealed-record-shape.skf");
	const auto opened_path = test_path("opened-record-shape.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::key256 key = key_from_seed(0x61);
	const anosecurekit::bytes plaintext = patterned_bytes((1024u * 1024u) + 17u, 43u);
	write_file(plain_path, plaintext);
	anosecurekit::seal_file(plain_path, sealed_path, key);
	const anosecurekit::bytes original = read_file(sealed_path);

	const std::size_t header_size = 50;
	const std::size_t first_record_size_offset = header_size + 4;
	const std::size_t first_record_flag_offset = header_size + 8;

	anosecurekit::bytes oversized_record = original;
	oversized_record[first_record_size_offset] = std::byte{0x00};
	oversized_record[first_record_size_offset + 1] = std::byte{0x10};
	oversized_record[first_record_size_offset + 2] = std::byte{0x00};
	oversized_record[first_record_size_offset + 3] = std::byte{0x01};
	write_file(sealed_path, oversized_record);
	expect_invalid_packet([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	anosecurekit::bytes short_non_final_record = original;
	short_non_final_record[first_record_size_offset] = std::byte{0x00};
	short_non_final_record[first_record_size_offset + 1] = std::byte{0x0f};
	short_non_final_record[first_record_size_offset + 2] = std::byte{0xff};
	short_non_final_record[first_record_size_offset + 3] = std::byte{0xff};
	write_file(sealed_path, short_non_final_record);
	expect_invalid_packet([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	anosecurekit::bytes early_final_record = original;
	early_final_record[first_record_flag_offset] = std::byte{0x01};
	write_file(sealed_path, early_final_record);
	expect_invalid_packet([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	anosecurekit::bytes invalid_final_flag = original;
	invalid_final_flag[first_record_flag_offset] = std::byte{0x02};
	write_file(sealed_path, invalid_final_flag);
	expect_invalid_packet([&] { anosecurekit::open_file(sealed_path, opened_path, key); });

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, RejectsNegativeCompatibilityFixtureNonFinalShortChunk)
{
	const auto sealed_path = test_path("negative-non-final-short-chunk.skf");
	const auto opened_path = test_path("negative-non-final-short-chunk-opened.bin");
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes fixture = anosecurekit::test::read_hex_fixture("negative/skf1-non-final-short-chunk.hex");
	write_file(sealed_path, fixture);

	expect_invalid_packet([&] { anosecurekit::open_file(sealed_path, opened_path, key_from_seed(0x00)); });

	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, RejectsNegativeCompatibilitySkf1FormatRuleFixtures)
{
	for (const auto &[label, fixture_name] : {
	         std::pair<std::string_view, std::string_view>{"missing-final-chunk", "negative/skf1-missing-final-chunk.hex"},
	         std::pair<std::string_view, std::string_view>{"chunk-after-final", "negative/skf1-chunk-after-final.hex"},
	         std::pair<std::string_view, std::string_view>{"non-monotonic-index", "negative/skf1-non-monotonic-index.hex"},
	         std::pair<std::string_view, std::string_view>{"bad-magic", "negative/skf1-bad-magic.hex"},
	         std::pair<std::string_view, std::string_view>{"unsupported-version", "negative/skf1-unsupported-version.hex"},
	         std::pair<std::string_view, std::string_view>{"unsupported-algorithm", "negative/skf1-unsupported-algorithm.hex"},
	         std::pair<std::string_view, std::string_view>{"unsupported-chunk-size", "negative/skf1-unsupported-chunk-size.hex"},
	         std::pair<std::string_view, std::string_view>{"truncated-record", "negative/skf1-truncated-record.hex"},
	         std::pair<std::string_view, std::string_view>{"record-oversized-plaintext", "negative/skf1-record-oversized-plaintext.hex"},
	         std::pair<std::string_view, std::string_view>{"record-unsupported-final-flag", "negative/skf1-record-unsupported-final-flag.hex"},
	     })
	{
		SCOPED_TRACE(label);
		const auto sealed_path = test_path("negative-skf1-" + std::string(label) + ".skf");
		const auto opened_path = test_path("negative-skf1-" + std::string(label) + "-opened.bin");
		std::filesystem::remove(sealed_path);
		std::filesystem::remove(opened_path);

		const anosecurekit::bytes fixture = anosecurekit::test::read_hex_fixture(fixture_name);
		write_file(sealed_path, fixture);

		expect_invalid_packet([&] { anosecurekit::open_file(sealed_path, opened_path, key_from_seed(0x00)); });

		std::filesystem::remove(sealed_path);
		std::filesystem::remove(opened_path);
	}
}

TEST(File, RoundTripsChunkBoundarySizes)
{
	constexpr std::size_t chunk_size = 1024u * 1024u;
	constexpr std::size_t header_size = 50u;
	constexpr std::size_t per_record_overhead = 9u + 16u;
	const anosecurekit::key256 key = key_from_seed(0x70);
	const anosecurekit::bytes aad = bytes_from_text("chunk-boundary");

	for (const std::size_t size : {chunk_size - 1u, chunk_size, chunk_size + 1u, chunk_size * 2u, (chunk_size * 2u) + 1u})
	{
		SCOPED_TRACE(size);
		const auto plain_path = test_path("plain-boundary-" + std::to_string(size) + ".bin");
		const auto sealed_path = test_path("sealed-boundary-" + std::to_string(size) + ".skf");
		const auto opened_path = test_path("opened-boundary-" + std::to_string(size) + ".bin");
		std::filesystem::remove(plain_path);
		std::filesystem::remove(sealed_path);
		std::filesystem::remove(opened_path);

		const anosecurekit::bytes plaintext = patterned_bytes(size, 17u);
		write_file(plain_path, plaintext);

		anosecurekit::seal_file(plain_path, sealed_path, key, aad);
		const anosecurekit::bytes sealed = read_file(sealed_path);
		const std::size_t record_count = (size + chunk_size - 1u) / chunk_size;
		EXPECT_EQ(sealed.size(), header_size + size + (record_count * per_record_overhead));

		anosecurekit::open_file(sealed_path, opened_path, key, aad);
		EXPECT_EQ(read_file(opened_path), plaintext);

		std::filesystem::remove(plain_path);
		std::filesystem::remove(sealed_path);
		std::filesystem::remove(opened_path);
	}
}

TEST(File, RoundTripsMultiChunkFile)
{
	const auto plain_path = test_path("plain-large.bin");
	const auto sealed_path = test_path("sealed-large.skf");
	const auto opened_path = test_path("opened-large.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	anosecurekit::bytes plaintext((1024u * 1024u * 2u) + 17u);
	for (std::size_t i = 0; i < plaintext.size(); ++i)
	{
		plaintext[i] = static_cast<std::byte>((i * 31u) & 0xffu);
	}

	const anosecurekit::key256 key = key_from_seed(0x20);
	write_file(plain_path, plaintext);
	anosecurekit::seal_file(plain_path, sealed_path, key);
	anosecurekit::open_file(sealed_path, opened_path, key);
	EXPECT_EQ(read_file(opened_path), plaintext);

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, VerifiesRawKeyFilesWithoutPlaintextOutput)
{
	const auto plain_path = test_path("verify-raw-plain.bin");
	const auto sealed_path = test_path("verify-raw-sealed.skf");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	const auto plaintext = patterned_bytes((1024u * 1024u) + 17u, 41u);
	const auto aad = bytes_from_text("verify:raw:aad");
	const auto key = key_from_seed(0x41);
	const auto wrong_key = key_from_seed(0x42);
	write_file(plain_path, plaintext);
	anosecurekit::seal_file(plain_path, sealed_path, key, aad);
	EXPECT_NO_THROW(anosecurekit::verify_file(sealed_path, key, aad));
	expect_generic_authentication_failure([&] { anosecurekit::verify_file(sealed_path, wrong_key, aad); });
	expect_generic_authentication_failure([&] { anosecurekit::verify_file(sealed_path, key, bytes_from_text("verify:wrong:aad")); });
	std::istringstream stream_input(string_from_bytes(read_file(sealed_path)), std::ios::binary);
	EXPECT_NO_THROW(anosecurekit::verify_file(stream_input, key, aad));
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
}

TEST(File, VerifiesPasswordFilesWithoutPlaintextOutput)
{
	const auto plain_path = test_path("verify-password-plain.bin");
	const auto sealed_path = test_path("verify-password-sealed.skp");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	const auto plaintext = patterned_bytes((1024u * 1024u) + 23u, 43u);
	const auto password = bytes_from_text("verify password");
	const auto wrong_password = bytes_from_text("wrong verify password");
	const auto aad = bytes_from_text("verify:password:aad");
	write_file(plain_path, plaintext);
	anosecurekit::seal_file_with_password(plain_path, sealed_path, password, aad);
	EXPECT_NO_THROW(anosecurekit::verify_file_with_password(sealed_path, password, aad));
	expect_generic_authentication_failure([&] { anosecurekit::verify_file_with_password(sealed_path, wrong_password, aad); });
	expect_generic_authentication_failure([&] { anosecurekit::verify_file_with_password(sealed_path, password, bytes_from_text("verify:wrong:aad")); });
	std::istringstream stream_input(string_from_bytes(read_file(sealed_path)), std::ios::binary);
	EXPECT_NO_THROW(anosecurekit::verify_file_with_password(stream_input, password, aad));
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
}

TEST(File, VerificationRejectsMalformedFilesAndUsesExistingErrors)
{
	const auto plain_path = test_path("verify-malformed-plain.bin");
	const auto raw_path = test_path("verify-malformed.skf");
	const auto password_path = test_path("verify-malformed.skp");
	const auto missing_path = test_path("verify-missing.skf");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(raw_path);
	std::filesystem::remove(password_path);
	std::filesystem::remove(missing_path);
	const auto key = key_from_seed(0x45);
	const auto password = bytes_from_text("verify malformed password");
	write_file(plain_path, bytes_from_text("verification malformed input"));
	anosecurekit::seal_file(plain_path, raw_path, key);
	anosecurekit::seal_file_with_password(plain_path, password_path, password);
	auto raw = read_file(raw_path); raw.pop_back(); write_file(raw_path, raw);
	auto packet = read_file(password_path); packet.push_back(std::byte{0x00}); write_file(password_path, packet);
	expect_invalid_packet([&] { anosecurekit::verify_file(raw_path, key); });
	expect_invalid_packet([&] { anosecurekit::verify_file_with_password(password_path, password); });
	expect_error([&] { anosecurekit::verify_file(missing_path, key); }, anosecurekit::error_code::backend_failure);
	expect_error([&] { anosecurekit::verify_file_with_password(password_path, {}); }, anosecurekit::error_code::invalid_input);
	std::filesystem::remove(plain_path);
	std::filesystem::remove(raw_path);
	std::filesystem::remove(password_path);
}

TEST(File, PasswordRoundTripsSmallFile)
{
	const auto plain_path = test_path("password-plain-small.bin");
	const auto sealed_path = test_path("password-sealed-small.skp");
	const auto opened_path = test_path("password-opened-small.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes plaintext = bytes_from_text("hello password file sealing");
	const anosecurekit::bytes password = bytes_from_text("correct horse battery staple");
	const anosecurekit::bytes aad = bytes_from_text("password:file:test");
	write_file(plain_path, plaintext);

	anosecurekit::seal_file_with_password(plain_path, sealed_path, password, aad);
	const anosecurekit::bytes sealed = read_file(sealed_path);
	ASSERT_GE(sealed.size(), 64u + 9u + plaintext.size() + 16u);
	EXPECT_EQ(sealed[0], std::byte{'S'});
	EXPECT_EQ(sealed[1], std::byte{'K'});
	EXPECT_EQ(sealed[2], std::byte{'P'});
	EXPECT_EQ(sealed[3], std::byte{'1'});
	EXPECT_EQ(sealed[4], std::byte{0x01});
	EXPECT_EQ(sealed[5], std::byte{0x01});
	EXPECT_EQ(sealed[6], std::byte{0x01});
	EXPECT_EQ(sealed[7], std::byte{0x00});

	anosecurekit::open_file_with_password(sealed_path, opened_path, password, aad);
	EXPECT_EQ(read_file(opened_path), plaintext);

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, PasswordRoundTripsStreams)
{
	const anosecurekit::bytes plaintext = patterned_bytes((1024u * 1024u) + 19u, 29u);
	const anosecurekit::bytes password = bytes_from_text("stream password");
	const anosecurekit::bytes aad = bytes_from_text("stream:password:file:test");

	std::istringstream plain_stream(string_from_bytes(plaintext), std::ios::binary);
	std::ostringstream sealed_stream(std::ios::binary);
	anosecurekit::seal_file_with_password(plain_stream, sealed_stream, password, aad);

	const anosecurekit::bytes sealed = bytes_from_text(sealed_stream.str());
	ASSERT_GE(sealed.size(), 64u + 9u + plaintext.size() + 16u);
	EXPECT_EQ(sealed[0], std::byte{'S'});
	EXPECT_EQ(sealed[1], std::byte{'K'});
	EXPECT_EQ(sealed[2], std::byte{'P'});
	EXPECT_EQ(sealed[3], std::byte{'1'});

	std::istringstream sealed_input(sealed_stream.str(), std::ios::binary);
	std::ostringstream opened_stream(std::ios::binary);
	anosecurekit::open_file_with_password(sealed_input, opened_stream, password, aad);

	EXPECT_EQ(bytes_from_text(opened_stream.str()), plaintext);
}

TEST(File, PasswordStreamRejectsTrailingDataBeforeWritingFinalPlaintext)
{
	const anosecurekit::bytes plaintext = bytes_from_text("password stream trailing plaintext");
	const anosecurekit::bytes password = bytes_from_text("stream trailing password");

	std::istringstream plain_stream(string_from_bytes(plaintext), std::ios::binary);
	std::ostringstream sealed_stream(std::ios::binary);
	anosecurekit::seal_file_with_password(plain_stream, sealed_stream, password);

	std::string sealed = sealed_stream.str();
	sealed.push_back('\0');

	std::istringstream sealed_input(sealed, std::ios::binary);
	std::ostringstream opened_stream(std::ios::binary);
	expect_invalid_packet([&] { anosecurekit::open_file_with_password(sealed_input, opened_stream, password); });
	EXPECT_TRUE(opened_stream.str().empty());
}

TEST(File, PasswordRoundTripsEmptyFile)
{
	const auto plain_path = test_path("password-plain-empty.bin");
	const auto sealed_path = test_path("password-sealed-empty.skp");
	const auto opened_path = test_path("password-opened-empty.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes password = bytes_from_text("empty file password");
	write_file(plain_path, {});

	anosecurekit::seal_file_with_password(plain_path, sealed_path, password);
	anosecurekit::open_file_with_password(sealed_path, opened_path, password);
	EXPECT_TRUE(read_file(opened_path).empty());

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, PasswordRoundTripsMultiChunkFile)
{
	const auto plain_path = test_path("password-plain-large.bin");
	const auto sealed_path = test_path("password-sealed-large.skp");
	const auto opened_path = test_path("password-opened-large.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes plaintext = patterned_bytes((1024u * 1024u * 2u) + 17u, 23u);
	const anosecurekit::bytes password = bytes_from_text("large file password");
	const anosecurekit::bytes aad = bytes_from_text("password:large");
	write_file(plain_path, plaintext);

	anosecurekit::seal_file_with_password(plain_path, sealed_path, password, aad);
	anosecurekit::open_file_with_password(sealed_path, opened_path, password, aad);
	EXPECT_EQ(read_file(opened_path), plaintext);

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, PasswordRejectsWrongPasswordAndAad)
{
	const auto plain_path = test_path("password-plain-auth.bin");
	const auto sealed_path = test_path("password-sealed-auth.skp");
	const auto opened_path = test_path("password-opened-auth.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes password = bytes_from_text("right password");
	const anosecurekit::bytes wrong_password = bytes_from_text("wrong password");
	const anosecurekit::bytes aad = bytes_from_text("aad");
	write_file(plain_path, bytes_from_text("password secret"));
	anosecurekit::seal_file_with_password(plain_path, sealed_path, password, aad);

	expect_generic_authentication_failure([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, wrong_password, aad); });
	expect_generic_authentication_failure([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password, bytes_from_text("wrong aad")); });

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, PasswordRemovesTemporaryOutputAfterOpenFailure)
{
	const auto plain_path = test_path("password-plain-open-failure-cleanup.bin");
	const auto sealed_path = test_path("password-sealed-open-failure-cleanup.skp");
	const auto opened_path = test_path("password-opened-open-failure-cleanup.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	remove_anosecurekit_temp_outputs_for(opened_path);

	const anosecurekit::bytes password = bytes_from_text("right cleanup password");
	const anosecurekit::bytes wrong_password = bytes_from_text("wrong cleanup password");
	write_file(plain_path, bytes_from_text("password cleanup on failure"));
	anosecurekit::seal_file_with_password(plain_path, sealed_path, password);

	expect_generic_authentication_failure([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, wrong_password); });

	EXPECT_FALSE(std::filesystem::exists(opened_path));
	EXPECT_FALSE(has_anosecurekit_temp_output_for(opened_path));

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	remove_anosecurekit_temp_outputs_for(opened_path);
}

TEST(File, PasswordRemovesPartialTemporaryOutputAfterLateOpenFailure)
{
	const auto plain_path = test_path("password-plain-late-open-failure-cleanup.bin");
	const auto sealed_path = test_path("password-sealed-late-open-failure-cleanup.skp");
	const auto opened_path = test_path("password-opened-late-open-failure-cleanup.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	remove_anosecurekit_temp_outputs_for(opened_path);

	const anosecurekit::bytes password = bytes_from_text("late cleanup password");
	anosecurekit::bytes plaintext((1024u * 1024u) + 19u);
	for (std::size_t i = 0; i < plaintext.size(); ++i)
	{
		plaintext[i] = static_cast<std::byte>((i * 41u) & 0xffu);
	}
	write_file(plain_path, plaintext);
	anosecurekit::seal_file_with_password(plain_path, sealed_path, password);

	anosecurekit::bytes sealed = read_file(sealed_path);
	sealed.back() ^= std::byte{0x01};
	write_file(sealed_path, sealed);

	expect_generic_authentication_failure([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); });

	EXPECT_FALSE(std::filesystem::exists(opened_path));
	EXPECT_FALSE(has_anosecurekit_temp_output_for(opened_path));

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	remove_anosecurekit_temp_outputs_for(opened_path);
}

TEST(File, PasswordRejectsExistingOutputAndEmptyPassword)
{
	const auto plain_path = test_path("password-plain-invalid.bin");
	const auto sealed_path = test_path("password-sealed-invalid.skp");
	const auto opened_path = test_path("password-opened-invalid.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes password = bytes_from_text("non-empty password");
	write_file(plain_path, bytes_from_text("input"));
	write_file(sealed_path, bytes_from_text("existing"));

	expect_error([&] { anosecurekit::seal_file_with_password(plain_path, sealed_path, password); }, anosecurekit::error_code::invalid_input);
	EXPECT_EQ(read_file(sealed_path), bytes_from_text("existing"));

	std::filesystem::remove(sealed_path);
	expect_error([&] { anosecurekit::seal_file_with_password(plain_path, sealed_path, anosecurekit::bytes{}); }, anosecurekit::error_code::invalid_input);

	anosecurekit::seal_file_with_password(plain_path, sealed_path, password);
	write_file(opened_path, bytes_from_text("existing output"));
	expect_error([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); }, anosecurekit::error_code::invalid_input);
	EXPECT_EQ(read_file(opened_path), bytes_from_text("existing output"));
	expect_error([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, anosecurekit::bytes{}); }, anosecurekit::error_code::invalid_input);

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, PasswordUsesUniqueTemporaryOutput)
{
	const auto plain_path = test_path("password-plain-temp-collision.bin");
	const auto sealed_path = test_path("password-sealed-temp-collision.skp");
	const auto opened_path = test_path("password-opened-temp-collision.bin");
	const auto sealed_temp_path = temp_path_for(sealed_path);
	const auto opened_temp_path = temp_path_for(opened_path);
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	std::filesystem::remove(sealed_temp_path);
	std::filesystem::remove(opened_temp_path);

	const anosecurekit::bytes password = bytes_from_text("temp collision password");
	const anosecurekit::bytes existing_temp = bytes_from_text("existing temp");
	const anosecurekit::bytes plaintext = bytes_from_text("password temp collision plaintext");
	write_file(plain_path, plaintext);
	write_file(sealed_temp_path, existing_temp);

	anosecurekit::seal_file_with_password(plain_path, sealed_path, password);
	EXPECT_TRUE(std::filesystem::exists(sealed_path));
	EXPECT_EQ(read_file(sealed_temp_path), existing_temp);

	write_file(opened_temp_path, existing_temp);

	anosecurekit::open_file_with_password(sealed_path, opened_path, password);
	EXPECT_EQ(read_file(opened_path), plaintext);
	EXPECT_EQ(read_file(opened_temp_path), existing_temp);

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	std::filesystem::remove(sealed_temp_path);
	std::filesystem::remove(opened_temp_path);
}

TEST(File, PasswordRejectsMalformedHeaderAndUnsupportedScryptParameters)
{
	const auto plain_path = test_path("password-plain-header.bin");
	const auto sealed_path = test_path("password-sealed-header.skp");
	const auto opened_path = test_path("password-opened-header.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes password = bytes_from_text("header password");
	write_file(plain_path, bytes_from_text("header"));
	anosecurekit::seal_file_with_password(plain_path, sealed_path, password);

	for (const std::size_t offset : {0u, 1u, 2u, 3u, 4u, 5u, 6u, 7u, 8u, 11u, 52u, 59u, 63u})
	{
		anosecurekit::bytes sealed = read_file(sealed_path);
		sealed[offset] ^= std::byte{0x01};
		write_file(sealed_path, sealed);
		expect_error([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); }, anosecurekit::error_code::invalid_packet);
		std::filesystem::remove(opened_path);
	}

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, PasswordDetectsTruncationAppendAndReorder)
{
	const auto plain_path = test_path("password-plain-shape.bin");
	const auto sealed_path = test_path("password-sealed-shape.skp");
	const auto opened_path = test_path("password-opened-shape.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	anosecurekit::bytes plaintext((1024u * 1024u * 2u) + 17u);
	for (std::size_t i = 0; i < plaintext.size(); ++i)
	{
		plaintext[i] = static_cast<std::byte>((i * 19u) & 0xffu);
	}

	const anosecurekit::bytes password = bytes_from_text("shape password");
	write_file(plain_path, plaintext);
	anosecurekit::seal_file_with_password(plain_path, sealed_path, password);
	const anosecurekit::bytes original = read_file(sealed_path);

	anosecurekit::bytes truncated = original;
	truncated.pop_back();
	write_file(sealed_path, truncated);
	expect_invalid_packet([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); });

	anosecurekit::bytes appended = original;
	appended.push_back(std::byte{0x00});
	write_file(sealed_path, appended);
	expect_invalid_packet([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); });

	const std::size_t header_size = 64;
	const std::size_t full_record_size = 9 + (1024u * 1024u) + 16;
	anosecurekit::bytes reordered = original;
	std::swap_ranges(
	    reordered.begin() + static_cast<std::ptrdiff_t>(header_size),
	    reordered.begin() + static_cast<std::ptrdiff_t>(header_size + full_record_size),
	    reordered.begin() + static_cast<std::ptrdiff_t>(header_size + full_record_size));
	write_file(sealed_path, reordered);
	expect_invalid_packet([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); });

	anosecurekit::bytes duplicate_index = original;
	std::fill_n(duplicate_index.begin() + static_cast<std::ptrdiff_t>(header_size + full_record_size), 4, std::byte{0x00});
	write_file(sealed_path, duplicate_index);
	expect_invalid_packet([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); });

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, PasswordRejectsMalformedRecordShape)
{
	const auto plain_path = test_path("password-plain-record-shape.bin");
	const auto sealed_path = test_path("password-sealed-record-shape.skp");
	const auto opened_path = test_path("password-opened-record-shape.bin");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes password = bytes_from_text("record shape password");
	const anosecurekit::bytes plaintext = patterned_bytes((1024u * 1024u) + 17u, 47u);
	write_file(plain_path, plaintext);
	anosecurekit::seal_file_with_password(plain_path, sealed_path, password);
	const anosecurekit::bytes original = read_file(sealed_path);

	const std::size_t header_size = 64;
	const std::size_t first_record_size_offset = header_size + 4;
	const std::size_t first_record_flag_offset = header_size + 8;

	anosecurekit::bytes oversized_record = original;
	oversized_record[first_record_size_offset] = std::byte{0x00};
	oversized_record[first_record_size_offset + 1] = std::byte{0x10};
	oversized_record[first_record_size_offset + 2] = std::byte{0x00};
	oversized_record[first_record_size_offset + 3] = std::byte{0x01};
	write_file(sealed_path, oversized_record);
	expect_invalid_packet([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); });

	anosecurekit::bytes short_non_final_record = original;
	short_non_final_record[first_record_size_offset] = std::byte{0x00};
	short_non_final_record[first_record_size_offset + 1] = std::byte{0x0f};
	short_non_final_record[first_record_size_offset + 2] = std::byte{0xff};
	short_non_final_record[first_record_size_offset + 3] = std::byte{0xff};
	write_file(sealed_path, short_non_final_record);
	expect_invalid_packet([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); });

	anosecurekit::bytes early_final_record = original;
	early_final_record[first_record_flag_offset] = std::byte{0x01};
	write_file(sealed_path, early_final_record);
	expect_invalid_packet([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); });

	anosecurekit::bytes invalid_final_flag = original;
	invalid_final_flag[first_record_flag_offset] = std::byte{0x02};
	write_file(sealed_path, invalid_final_flag);
	expect_invalid_packet([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); });

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, PasswordRejectsNegativeCompatibilityFixtureUnsupportedFlags)
{
	const auto sealed_path = test_path("negative-unsupported-flags.skp");
	const auto opened_path = test_path("negative-unsupported-flags-opened.bin");
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);

	const anosecurekit::bytes password = bytes_from_text("negative fixture password");
	const anosecurekit::bytes fixture = anosecurekit::test::read_hex_fixture("negative/skp1-unsupported-flags.hex");
	write_file(sealed_path, fixture);

	expect_invalid_packet([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); });

	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
}

TEST(File, PasswordRejectsNegativeCompatibilitySkp1FormatRuleFixtures)
{
	for (const auto &[label, fixture_name] : {
	         std::pair<std::string_view, std::string_view>{"missing-final-chunk", "negative/skp1-missing-final-chunk.hex"},
	         std::pair<std::string_view, std::string_view>{"chunk-after-final", "negative/skp1-chunk-after-final.hex"},
	         std::pair<std::string_view, std::string_view>{"non-monotonic-index", "negative/skp1-non-monotonic-index.hex"},
	         std::pair<std::string_view, std::string_view>{"bad-magic", "negative/skp1-bad-magic.hex"},
	         std::pair<std::string_view, std::string_view>{"unsupported-version", "negative/skp1-unsupported-version.hex"},
	         std::pair<std::string_view, std::string_view>{"unsupported-cipher", "negative/skp1-unsupported-cipher.hex"},
	         std::pair<std::string_view, std::string_view>{"unsupported-kdf", "negative/skp1-unsupported-kdf.hex"},
	         std::pair<std::string_view, std::string_view>{"unsupported-chunk-size", "negative/skp1-unsupported-chunk-size.hex"},
	         std::pair<std::string_view, std::string_view>{"unsupported-scrypt-params", "negative/skp1-unsupported-scrypt-params.hex"},
	         std::pair<std::string_view, std::string_view>{"unsupported-scrypt-n", "negative/skp1-unsupported-scrypt-n.hex"},
	         std::pair<std::string_view, std::string_view>{"unsupported-scrypt-r", "negative/skp1-unsupported-scrypt-r.hex"},
	         std::pair<std::string_view, std::string_view>{"unsupported-scrypt-p", "negative/skp1-unsupported-scrypt-p.hex"},
	         std::pair<std::string_view, std::string_view>{"truncated-record", "negative/skp1-truncated-record.hex"},
	         std::pair<std::string_view, std::string_view>{"record-oversized-plaintext", "negative/skp1-record-oversized-plaintext.hex"},
	         std::pair<std::string_view, std::string_view>{"record-unsupported-final-flag", "negative/skp1-record-unsupported-final-flag.hex"},
	     })
	{
		SCOPED_TRACE(label);
		const auto sealed_path = test_path("negative-skp1-" + std::string(label) + ".skp");
		const auto opened_path = test_path("negative-skp1-" + std::string(label) + "-opened.bin");
		std::filesystem::remove(sealed_path);
		std::filesystem::remove(opened_path);

		const anosecurekit::bytes password = bytes_from_text("negative fixture password");
		const anosecurekit::bytes fixture = anosecurekit::test::read_hex_fixture(fixture_name);
		write_file(sealed_path, fixture);

		expect_invalid_packet([&] { anosecurekit::open_file_with_password(sealed_path, opened_path, password); });

		std::filesystem::remove(sealed_path);
		std::filesystem::remove(opened_path);
	}
}
