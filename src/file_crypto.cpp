// SPDX-License-Identifier: MPL-2.0
#include "file_detail.hpp"

#include <algorithm>
#include <tuple>

#include "anosecurekit/error.hpp"

#include "crypto_backend.hpp"
#include "wipe.hpp"

namespace anosecurekit::detail
{

namespace
{

constexpr std::array<std::byte, 4> kMagic{std::byte{'S'}, std::byte{'K'}, std::byte{'F'}, std::byte{'1'}};
constexpr std::array<std::byte, 4> kPasswordMagic{std::byte{'S'}, std::byte{'K'}, std::byte{'P'}, std::byte{'1'}};
constexpr std::byte kVersion{0x01};
constexpr std::byte kAlgorithm{0x01};
constexpr std::byte kPasswordCipherAes256Gcm{0x01};
constexpr std::byte kPasswordKdfScrypt{0x01};
constexpr std::byte kPasswordFlagsNone{0x00};
constexpr std::uint32_t kScryptN = 32768u;
constexpr std::uint32_t kScryptR = 8u;
constexpr std::uint32_t kScryptP = 1u;
constexpr std::uint64_t kScryptMaxMemory = 64ull * 1024ull * 1024ull;

void store_u32_be(std::byte *output, std::uint32_t value)
{
	output[0] = static_cast<std::byte>((value >> 24) & 0xffu);
	output[1] = static_cast<std::byte>((value >> 16) & 0xffu);
	output[2] = static_cast<std::byte>((value >> 8) & 0xffu);
	output[3] = static_cast<std::byte>(value & 0xffu);
}

std::uint32_t read_u32_be(std::span<const std::byte, 4> input)
{
	return (static_cast<std::uint32_t>(input[0]) << 24) |
	       (static_cast<std::uint32_t>(input[1]) << 16) |
	       (static_cast<std::uint32_t>(input[2]) << 8) |
	       static_cast<std::uint32_t>(input[3]);
}

bytes bytes_from_literal(const char *text)
{
	bytes output;
	while (*text != '\0')
	{
		output.push_back(static_cast<std::byte>(static_cast<unsigned char>(*text)));
		++text;
	}
	return output;
}

} // namespace

[[noreturn]] void throw_backend_failure(const char *message)
{
	throw anosecurekit::error(anosecurekit::error_code::backend_failure, message);
}

[[noreturn]] void throw_invalid_packet()
{
	throw anosecurekit::error(anosecurekit::error_code::invalid_packet, "Invalid file sealing packet");
}

FileHeader make_header()
{
	FileHeader header{};
	std::copy(kMagic.begin(), kMagic.end(), header.serialized.begin());
	header.serialized[4] = kVersion;
	header.serialized[5] = kAlgorithm;
	store_u32_be(header.serialized.data() + 6, kChunkSize);

	const bytes salt = crypto_backend::random_bytes(kSaltSize);
	const bytes nonce_prefix = crypto_backend::random_bytes(kNoncePrefixSize);
	std::copy(salt.begin(), salt.end(), header.salt.begin());
	std::copy(nonce_prefix.begin(), nonce_prefix.end(), header.nonce_prefix.begin());
	std::copy(header.salt.begin(), header.salt.end(), header.serialized.begin() + 10);
	std::copy(header.nonce_prefix.begin(), header.nonce_prefix.end(), header.serialized.begin() + 42);
	return header;
}

FileHeader parse_header(std::span<const std::byte, kHeaderSize> data)
{
	FileHeader header{};
	std::copy(data.begin(), data.end(), header.serialized.begin());
	if (!std::equal(kMagic.begin(), kMagic.end(), data.begin()) || data[4] != kVersion || data[5] != kAlgorithm)
	{
		throw_invalid_packet();
	}

	if (read_u32_be(data.template subspan<6, 4>()) != kChunkSize)
	{
		throw_invalid_packet();
	}

	std::copy(data.begin() + 10, data.begin() + 42, header.salt.begin());
	std::copy(data.begin() + 42, data.end(), header.nonce_prefix.begin());
	return header;
}

PasswordFileHeader make_password_header()
{
	PasswordFileHeader header{};
	std::copy(kPasswordMagic.begin(), kPasswordMagic.end(), header.serialized.begin());
	header.serialized[4] = kVersion;
	header.serialized[5] = kPasswordCipherAes256Gcm;
	header.serialized[6] = kPasswordKdfScrypt;
	header.serialized[7] = kPasswordFlagsNone;
	store_u32_be(header.serialized.data() + 8, kChunkSize);

	const bytes salt = crypto_backend::random_bytes(kSaltSize);
	const bytes nonce_prefix = crypto_backend::random_bytes(kNoncePrefixSize);
	std::copy(salt.begin(), salt.end(), header.salt.begin());
	std::copy(nonce_prefix.begin(), nonce_prefix.end(), header.nonce_prefix.begin());
	std::copy(header.salt.begin(), header.salt.end(), header.serialized.begin() + 12);
	std::copy(header.nonce_prefix.begin(), header.nonce_prefix.end(), header.serialized.begin() + 44);
	store_u32_be(header.serialized.data() + 52, header.scrypt_n);
	store_u32_be(header.serialized.data() + 56, header.scrypt_r);
	store_u32_be(header.serialized.data() + 60, header.scrypt_p);
	return header;
}

PasswordFileHeader parse_password_header(std::span<const std::byte, kPasswordHeaderSize> data)
{
	PasswordFileHeader header{};
	std::copy(data.begin(), data.end(), header.serialized.begin());
	if (!std::equal(kPasswordMagic.begin(), kPasswordMagic.end(), data.begin()) || data[4] != kVersion ||
	    data[5] != kPasswordCipherAes256Gcm || data[6] != kPasswordKdfScrypt || data[7] != kPasswordFlagsNone)
	{
		throw_invalid_packet();
	}

	if (read_u32_be(data.template subspan<8, 4>()) != kChunkSize)
	{
		throw_invalid_packet();
	}

	std::copy(data.begin() + 12, data.begin() + 44, header.salt.begin());
	std::copy(data.begin() + 44, data.begin() + 52, header.nonce_prefix.begin());
	header.scrypt_n = read_u32_be(data.template subspan<52, 4>());
	header.scrypt_r = read_u32_be(data.template subspan<56, 4>());
	header.scrypt_p = read_u32_be(data.template subspan<60, 4>());
	if (header.scrypt_n != kScryptN || header.scrypt_r != kScryptR || header.scrypt_p != kScryptP)
	{
		throw_invalid_packet();
	}

	return header;
}

key256 derive_file_key(const key256 &master_key, const FileHeader &header)
{
	// Wire-format v1 compatibility string; changing it breaks existing SKF1 files.
	const bytes info = bytes_from_literal("anosecurekit file sealing v1");
	bytes okm = crypto_backend::hkdf_sha256(std::span<const std::byte>(master_key), header.salt, info, key256{}.size());
	const internal::wipe_on_exit wipe_okm{std::span<std::byte>(okm)};
	key256 file_key{};
	std::copy_n(okm.begin(), file_key.size(), file_key.begin());
	return file_key;
}

void require_non_empty_password(std::span<const std::byte> password)
{
	if (password.empty())
	{
		throw anosecurekit::error(anosecurekit::error_code::invalid_input, "password must not be empty");
	}
}

key256 derive_password_file_key(std::span<const std::byte> password, const PasswordFileHeader &header)
{
	require_non_empty_password(password);
	const crypto_backend::ScryptParams params{header.scrypt_n, header.scrypt_r, header.scrypt_p, kScryptMaxMemory};
	return crypto_backend::scrypt_key(password, header.salt, params);
}

std::array<std::byte, kNonceSize> make_nonce(std::span<const std::byte> nonce_prefix, std::uint32_t chunk_index)
{
	std::array<std::byte, kNonceSize> nonce{};
	std::copy(nonce_prefix.begin(), nonce_prefix.end(), nonce.begin());
	store_u32_be(nonce.data() + kNoncePrefixSize, chunk_index);
	return nonce;
}

RecordHeader make_record_header(std::uint32_t index, std::uint32_t plaintext_size, std::byte final_flag)
{
	RecordHeader record{};
	record.index = index;
	record.plaintext_size = plaintext_size;
	record.final_flag = final_flag;
	store_u32_be(record.serialized.data(), index);
	store_u32_be(record.serialized.data() + 4, plaintext_size);
	record.serialized[8] = final_flag;
	return record;
}

RecordHeader parse_record_header(std::span<const std::byte, kRecordHeaderSize> data)
{
	RecordHeader record{};
	std::copy(data.begin(), data.end(), record.serialized.begin());
	record.index = read_u32_be(data.template subspan<0, 4>());
	record.plaintext_size = read_u32_be(data.template subspan<4, 4>());
	record.final_flag = data[8];
	if (record.final_flag != kNotFinal && record.final_flag != kFinal)
	{
		throw_invalid_packet();
	}
	if (record.plaintext_size > kChunkSize)
	{
		throw_invalid_packet();
	}
	return record;
}

bytes make_chunk_aad(
    std::span<const std::byte> serialized_header,
    const RecordHeader &record,
    std::span<const std::byte> caller_aad)
{
	bytes aad;
	aad.reserve(serialized_header.size() + record.serialized.size() + caller_aad.size());
	aad.insert(aad.end(), serialized_header.begin(), serialized_header.end());
	aad.insert(aad.end(), record.serialized.begin(), record.serialized.end());
	aad.insert(aad.end(), caller_aad.begin(), caller_aad.end());
	return aad;
}

EncryptedChunk encrypt_chunk(
    std::span<const std::byte> plaintext,
    const key256 &file_key,
    std::span<const std::byte> nonce,
    std::span<const std::byte> aad)
{
	const crypto_backend::Aes256GcmResult result = crypto_backend::aes256_gcm_encrypt(plaintext, file_key, nonce, aad);
	EncryptedChunk output{};
	output.ciphertext = result.ciphertext;
	static_assert(std::tuple_size_v<decltype(output.tag)> == std::tuple_size_v<decltype(result.tag)>);
	std::copy(result.tag.begin(), result.tag.end(), output.tag.begin());
	return output;
}

bytes decrypt_chunk(
    std::span<const std::byte> ciphertext,
    std::span<const std::byte> tag,
    const key256 &file_key,
    std::span<const std::byte> nonce,
    std::span<const std::byte> aad)
{
	return crypto_backend::aes256_gcm_decrypt(ciphertext, tag, file_key, nonce, aad);
}

} // namespace anosecurekit::detail
