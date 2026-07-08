// SPDX-License-Identifier: MPL-2.0
#pragma once

#include "anosecurekit/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <span>

namespace anosecurekit::detail::crypto_backend
{

struct ScryptParams
{
	std::uint64_t n{};
	std::uint32_t r{};
	std::uint32_t p{};
	std::uint64_t max_memory{};
};

struct Aes256GcmResult
{
	bytes ciphertext;
	std::array<std::byte, 16> tag{};
};

class Aes256GcmEncryptContext
{
public:
	Aes256GcmEncryptContext(const key256 &key, std::span<const std::byte> nonce);
	~Aes256GcmEncryptContext();
	Aes256GcmEncryptContext(Aes256GcmEncryptContext &&) noexcept;
	Aes256GcmEncryptContext &operator=(Aes256GcmEncryptContext &&) noexcept;
	Aes256GcmEncryptContext(const Aes256GcmEncryptContext &) = delete;
	Aes256GcmEncryptContext &operator=(const Aes256GcmEncryptContext &) = delete;

	void update_aad(std::span<const std::byte> aad);
	bytes update(std::span<const std::byte> plaintext);
	std::array<std::byte, 16> finalize();

private:
	struct Impl;
	std::unique_ptr<Impl> impl_;
};

class Aes256GcmDecryptContext
{
public:
	Aes256GcmDecryptContext(const key256 &key, std::span<const std::byte> nonce);
	~Aes256GcmDecryptContext();
	Aes256GcmDecryptContext(Aes256GcmDecryptContext &&) noexcept;
	Aes256GcmDecryptContext &operator=(Aes256GcmDecryptContext &&) noexcept;
	Aes256GcmDecryptContext(const Aes256GcmDecryptContext &) = delete;
	Aes256GcmDecryptContext &operator=(const Aes256GcmDecryptContext &) = delete;

	void update_aad(std::span<const std::byte> aad);
	bytes update(std::span<const std::byte> ciphertext);
	bytes finalize(std::span<const std::byte> tag);

private:
	struct Impl;
	std::unique_ptr<Impl> impl_;
};

digest256 sha256(std::span<const std::byte> input);
digest256 hmac_sha256(std::span<const std::byte> key, std::span<const std::byte> input);
bytes hkdf_sha256(
    std::span<const std::byte> key_material,
    std::span<const std::byte> salt,
    std::span<const std::byte> info,
    std::size_t output_size);
bytes random_bytes(std::size_t size);
key256 generate_key();
key256 scrypt_key(std::span<const std::byte> password, std::span<const std::byte> salt, const ScryptParams &params);
Aes256GcmResult aes256_gcm_encrypt(
    std::span<const std::byte> plaintext,
    const key256 &key,
    std::span<const std::byte> nonce,
    std::span<const std::byte> aad);
bytes aes256_gcm_decrypt(
    std::span<const std::byte> ciphertext,
    std::span<const std::byte> tag,
    const key256 &key,
    std::span<const std::byte> nonce,
    std::span<const std::byte> aad);

} // namespace anosecurekit::detail::crypto_backend
