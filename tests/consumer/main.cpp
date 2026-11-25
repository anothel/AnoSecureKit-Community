// SPDX-License-Identifier: MPL-2.0
#include <cstddef>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <optional>
#include <span>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>

#include "anosecurekit/anosecurekit.hpp"

namespace
{

constexpr std::size_t kPacketPrefixSize = 17;
constexpr std::size_t kPacketTagSize = 16;
constexpr std::size_t kFileRecordSize = 1024 * 1024;

anosecurekit::bytes ascii_bytes(std::string_view text)
{
	anosecurekit::bytes result;
	result.reserve(text.size());
	for (const char ch : text)
	{
		result.push_back(static_cast<std::byte>(ch));
	}
	return result;
}

void write_file(const std::filesystem::path &path, const anosecurekit::bytes &bytes)
{
	std::ofstream out(path, std::ios::binary | std::ios::trunc);
	out.write(reinterpret_cast<const char *>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
}

anosecurekit::bytes read_file(const std::filesystem::path &path)
{
	std::ifstream in(path, std::ios::binary);
	const std::string data{std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>()};
	anosecurekit::bytes result;
	result.reserve(data.size());
	for (const unsigned char ch : data)
	{
		result.push_back(static_cast<std::byte>(ch));
	}
	return result;
}

std::string string_from_bytes(const anosecurekit::bytes &bytes)
{
	std::string result;
	result.reserve(bytes.size());
	for (const std::byte byte : bytes)
	{
		result.push_back(static_cast<char>(std::to_integer<unsigned char>(byte)));
	}
	return result;
}

void require(bool condition, std::string_view scenario, std::string_view expectation)
{
	if (!condition)
	{
		throw std::runtime_error(std::string(scenario) + ": " + std::string(expectation));
	}
}

void check_packet_consumer(
    std::string_view scenario, std::span<const std::byte> packet, const anosecurekit::bytes &plaintext,
    const anosecurekit::key256 &key, const anosecurekit::bytes &aad, std::optional<anosecurekit::error_code> expected_error)
{
	anosecurekit::bytes published;
	std::optional<anosecurekit::error_code> failure;
	try
	{
		anosecurekit::packet_decryptor decryptor(key, aad);
		decryptor.begin(packet.first(kPacketPrefixSize));
		auto pending = decryptor.update(packet.subspan(kPacketPrefixSize, plaintext.size()));
		require(pending.size() == plaintext.size() && published.empty(), scenario, "update must only stage plaintext");
		const auto tail = decryptor.finalize(packet.last(kPacketTagSize));
		pending.insert(pending.end(), tail.begin(), tail.end());
		published = std::move(pending);
	}
	catch (const anosecurekit::error &ex)
	{
		failure = ex.code();
	}
	require(failure == expected_error, scenario, "unexpected finalization result");
	require(failure ? published.empty() : published == plaintext, scenario, "unexpected published packet output");
}

template <typename Open, typename Credential>
void check_file_stream_consumer(
    std::string_view format, const std::string &sealed, std::string_view plaintext,
    Open open, const Credential &credential, const Credential &wrong_credential)
{
	using anosecurekit::error_code;
	const auto check_open = [&](std::string_view name, const std::string &input, const Credential &secret,
	                            std::optional<error_code> expected_error, std::string_view expected_bytes) {
		const auto scenario = std::string(format) + " " + std::string(name);
		const std::string previous_output = "previous consumer output";
		std::string published = previous_output;
		std::optional<error_code> failure;
		{
			std::istringstream ciphertext(input, std::ios::in | std::ios::binary);
			std::ostringstream pending(std::ios::out | std::ios::binary);
			try
			{
				open(ciphertext, pending, secret);
				published = std::move(pending).str();
			}
			catch (const anosecurekit::error &ex)
			{
				failure = ex.code();
				require(pending.view() == expected_bytes, scenario, "unexpected quarantined bytes before discard");
			}
		}
		require(failure == expected_error, scenario, "unexpected stream open result");
		require(published == (failure ? std::string_view(previous_output) : expected_bytes),
		    scenario, "unexpected published stream output");
	};

	const auto prefix = plaintext.substr(0, kFileRecordSize);
	auto bad_tag = sealed;
	bad_tag.back() = static_cast<char>(static_cast<unsigned char>(bad_tag.back()) ^ 1u);
	check_open("valid", sealed, credential, std::nullopt, plaintext);
	check_open("final tag", bad_tag, credential, error_code::authentication_failed, prefix);
	check_open("truncated", sealed.substr(0, sealed.size() - 1), credential, error_code::invalid_packet, prefix);
	check_open("wrong credential", sealed, wrong_credential, error_code::authentication_failed, {});
	check_open("trailing input", sealed + "x", credential, error_code::invalid_packet, prefix);
}

} // namespace

int main()
{
	const auto plaintext = ascii_bytes("AnoSecureKit consumer sample plaintext");
	const auto aad = ascii_bytes("AnoSecureKit consumer sample aad");
	const auto key = anosecurekit::generate_key();

	const auto from_hex = anosecurekit::hex_decode(anosecurekit::hex_encode(plaintext));
	const auto from_base64 = anosecurekit::base64_decode(anosecurekit::base64_encode(from_hex));
	const auto from_base64url = anosecurekit::base64url_decode(anosecurekit::base64url_encode(from_base64));
	const auto digest = anosecurekit::sha256(ascii_bytes("abc"));
	const auto hmac = anosecurekit::hmac_sha256(ascii_bytes("key"), ascii_bytes("The quick brown fox jumps over the lazy dog"));
	const auto hkdf = anosecurekit::hkdf_sha256(ascii_bytes("ikm"), ascii_bytes("salt"), ascii_bytes("info"), 16);
	const auto random = anosecurekit::random_bytes(8);
	const bool version_api_ok = anosecurekit::version() == ANOSECUREKIT_EXPECTED_VERSION &&
	                            anosecurekit::version_major() == ANOSECUREKIT_EXPECTED_VERSION_MAJOR &&
	                            anosecurekit::version_minor() == ANOSECUREKIT_EXPECTED_VERSION_MINOR &&
	                            anosecurekit::version_patch() == ANOSECUREKIT_EXPECTED_VERSION_PATCH;
	bool error_api_ok = false;
	try
	{
		(void)anosecurekit::random_token(0);
	}
	catch (const anosecurekit::error &ex)
	{
		error_api_ok = ex.code() == anosecurekit::error_code::invalid_input &&
		               !std::string_view(ex.what()).empty();
	}

	const auto packet = anosecurekit::encrypt(plaintext, key, aad);
	const auto roundtrip = anosecurekit::decrypt(packet, key, aad);
	anosecurekit::packet_encryptor packet_encryptor(key, aad);
	auto streaming_packet = packet_encryptor.begin();
	const auto stream_part1 = packet_encryptor.update(std::span<const std::byte>(plaintext).first(10));
	const auto stream_part2 = packet_encryptor.update(std::span<const std::byte>(plaintext).subspan(10));
	const auto stream_tag = packet_encryptor.finalize();
	streaming_packet.insert(streaming_packet.end(), stream_part1.begin(), stream_part1.end());
	streaming_packet.insert(streaming_packet.end(), stream_part2.begin(), stream_part2.end());
	streaming_packet.insert(streaming_packet.end(), stream_tag.begin(), stream_tag.end());
	const auto streaming_roundtrip = anosecurekit::decrypt(streaming_packet, key, aad);

	check_packet_consumer("SKT1 valid", packet, plaintext, key, aad, std::nullopt);
	auto bad_packet = packet;
	bad_packet.back() ^= std::byte{1};
	check_packet_consumer("SKT1 final tag", bad_packet, plaintext, key, aad,
	    anosecurekit::error_code::authentication_failed);

	const auto wrapped_key = anosecurekit::wrap_key(key, key, aad);
	const auto unwrapped_key = anosecurekit::unwrap_key(wrapped_key, key, aad);
	const std::string token = anosecurekit::random_token(32);

	const auto plain_path = std::filesystem::temp_directory_path() / "anosecurekit-consumer-plain.bin";
	const auto sealed_path = std::filesystem::temp_directory_path() / "anosecurekit-consumer-sealed.skf";
	const auto opened_path = std::filesystem::temp_directory_path() / "anosecurekit-consumer-opened.bin";
	const auto password_sealed_path = std::filesystem::temp_directory_path() / "anosecurekit-consumer-password-sealed.skp";
	const auto password_opened_path = std::filesystem::temp_directory_path() / "anosecurekit-consumer-password-opened.bin";
	const auto password = ascii_bytes("AnoSecureKit consumer password");
	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	std::filesystem::remove(password_sealed_path);
	std::filesystem::remove(password_opened_path);

	write_file(plain_path, plaintext);
	anosecurekit::seal_file(plain_path, sealed_path, key, aad);
	anosecurekit::verify_file(sealed_path, key, aad);
	anosecurekit::open_file(sealed_path, opened_path, key, aad);
	const auto opened = read_file(opened_path);
	anosecurekit::seal_file_with_password(plain_path, password_sealed_path, password, aad);
	anosecurekit::verify_file_with_password(password_sealed_path, password, aad);
	anosecurekit::open_file_with_password(password_sealed_path, password_opened_path, password, aad);
	const auto password_opened = read_file(password_opened_path);

	const auto file_plaintext = std::string(kFileRecordSize, 'x') + string_from_bytes(plaintext);
	std::istringstream stream_plaintext(file_plaintext, std::ios::in | std::ios::binary);
	std::ostringstream stream_sealed(std::ios::out | std::ios::binary);
	anosecurekit::seal_file(stream_plaintext, stream_sealed, key, aad);
	std::istringstream stream_verify_ciphertext(stream_sealed.str(), std::ios::in | std::ios::binary);
	anosecurekit::verify_file(stream_verify_ciphertext, key, aad);
	auto wrong_key = key;
	wrong_key.front() ^= std::byte{1};
	const auto open_with_key = [&](std::istream &input, std::ostream &pending, const anosecurekit::key256 &open_key) {
		anosecurekit::open_file(input, pending, open_key, aad);
	};
	check_file_stream_consumer("SKF1", stream_sealed.str(), file_plaintext, open_with_key, key, wrong_key);

	std::istringstream password_stream_plaintext(file_plaintext, std::ios::in | std::ios::binary);
	std::ostringstream password_stream_sealed(std::ios::out | std::ios::binary);
	anosecurekit::seal_file_with_password(password_stream_plaintext, password_stream_sealed, password, aad);
	std::istringstream password_stream_verify_ciphertext(password_stream_sealed.str(), std::ios::in | std::ios::binary);
	anosecurekit::verify_file_with_password(password_stream_verify_ciphertext, password, aad);
	const auto open_with_password = [&](std::istream &input, std::ostream &pending, const anosecurekit::bytes &open_password) {
		anosecurekit::open_file_with_password(input, pending, open_password, aad);
	};
	check_file_stream_consumer("SKP1", password_stream_sealed.str(), file_plaintext, open_with_password,
	    password, ascii_bytes("wrong consumer password"));

	std::filesystem::remove(plain_path);
	std::filesystem::remove(sealed_path);
	std::filesystem::remove(opened_path);
	std::filesystem::remove(password_sealed_path);
	std::filesystem::remove(password_opened_path);

	const bool utility_api_ok = from_base64url == plaintext &&
	                            anosecurekit::hex_encode(digest) ==
	                                "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" &&
	                            anosecurekit::hex_encode(hmac) ==
	                                "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8" &&
	                            hkdf.size() == 16 && random.size() == 8 && error_api_ok &&
	                            anosecurekit::constant_time_equal(digest, digest);

	return version_api_ok && utility_api_ok && roundtrip == plaintext && streaming_roundtrip == plaintext &&
	               unwrapped_key == key && opened == plaintext && password_opened == plaintext && !token.empty()
	           ? 0
	           : 1;
}
