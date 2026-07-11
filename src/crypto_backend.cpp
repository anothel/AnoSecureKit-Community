// SPDX-License-Identifier: MPL-2.0
#include "crypto_backend.hpp"

#include <openssl/core_names.h>
#include <openssl/evp.h>
#include <openssl/kdf.h>
#include <openssl/params.h>
#include <openssl/rand.h>

#include <algorithm>
#include <limits>
#include <memory>
#include <string>

#include "anosecurekit/error.hpp"

#include "internal/secure_wipe.hpp"

namespace anosecurekit::detail::crypto_backend
{
namespace
{

using CipherContext = std::unique_ptr<EVP_CIPHER_CTX, decltype(&EVP_CIPHER_CTX_free)>;
using DigestContext = std::unique_ptr<EVP_MD_CTX, decltype(&EVP_MD_CTX_free)>;
using Kdf = std::unique_ptr<EVP_KDF, decltype(&EVP_KDF_free)>;
using KdfContext = std::unique_ptr<EVP_KDF_CTX, decltype(&EVP_KDF_CTX_free)>;

[[noreturn]] void throw_backend_failure(const char *message)
{
	throw anosecurekit::error(anosecurekit::error_code::backend_failure, message);
}

[[noreturn]] void throw_authentication_failed()
{
	throw anosecurekit::error(anosecurekit::error_code::authentication_failed, "File authentication failed");
}

[[noreturn]] void throw_aead_authentication_failed()
{
	throw anosecurekit::error(anosecurekit::error_code::authentication_failed, "AEAD authentication failed");
}

unsigned char *openssl_data(std::byte *data)
{
	return reinterpret_cast<unsigned char *>(data);
}

const unsigned char *openssl_data(std::span<const std::byte> data)
{
	return reinterpret_cast<const unsigned char *>(data.data());
}

int int_size(std::size_t size, const char *name)
{
	if (size > static_cast<std::size_t>(std::numeric_limits<int>::max()))
	{
		throw anosecurekit::error(anosecurekit::error_code::invalid_input, std::string(name) + " exceeds OpenSSL update limit");
	}
	return static_cast<int>(size);
}

CipherContext make_aes256_gcm_context()
{
	CipherContext context(EVP_CIPHER_CTX_new(), EVP_CIPHER_CTX_free);
	if (context == nullptr || EVP_aes_256_gcm() == nullptr)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}
	return context;
}

void update_aad_impl(EVP_CIPHER_CTX *context, std::span<const std::byte> aad)
{
	const int aad_size = int_size(aad.size(), "AAD");
	if (aad_size == 0)
	{
		return;
	}

	int unused = 0;
	if (EVP_CipherUpdate(context, nullptr, &unused, openssl_data(aad), aad_size) != 1)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}
}

void fill_random(unsigned char *output, std::size_t size, bool secret)
{
	while (size > 0)
	{
		const std::size_t chunk_size = std::min<std::size_t>(size, std::numeric_limits<int>::max());
		const auto chunk = static_cast<int>(chunk_size);
		const int ok = secret ? RAND_priv_bytes(output, chunk) : RAND_bytes(output, chunk);
		if (ok != 1)
		{
			throw_backend_failure(secret ? "OpenSSL RAND_priv_bytes failed" : "OpenSSL RAND_bytes failed");
		}
		output += chunk;
		size -= static_cast<std::size_t>(chunk);
	}
}

void initialize_encrypt_context(EVP_CIPHER_CTX *context, const key256 &key, std::span<const std::byte> nonce)
{
	const auto key_span = std::span<const std::byte>(key);
	const bool initialized =
	    EVP_EncryptInit_ex(context, EVP_aes_256_gcm(), nullptr, nullptr, nullptr) == 1 &&
	    EVP_CIPHER_CTX_ctrl(context, EVP_CTRL_GCM_SET_IVLEN, static_cast<int>(nonce.size()), nullptr) == 1 &&
	    EVP_EncryptInit_ex(context, nullptr, nullptr, openssl_data(key_span), openssl_data(nonce)) == 1;
	if (!initialized)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}
}

void initialize_decrypt_context(EVP_CIPHER_CTX *context, const key256 &key, std::span<const std::byte> nonce)
{
	const auto key_span = std::span<const std::byte>(key);
	const bool initialized =
	    EVP_DecryptInit_ex(context, EVP_aes_256_gcm(), nullptr, nullptr, nullptr) == 1 &&
	    EVP_CIPHER_CTX_ctrl(context, EVP_CTRL_GCM_SET_IVLEN, static_cast<int>(nonce.size()), nullptr) == 1 &&
	    EVP_DecryptInit_ex(context, nullptr, nullptr, openssl_data(key_span), openssl_data(nonce)) == 1;
	if (!initialized)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}
}

} // namespace

struct Aes256GcmEncryptContext::Impl
{
	explicit Impl(CipherContext input_context) : context(std::move(input_context))
	{
	}

	CipherContext context;
};

struct Aes256GcmDecryptContext::Impl
{
	explicit Impl(CipherContext input_context) : context(std::move(input_context))
	{
	}

	CipherContext context;
};

Aes256GcmEncryptContext::Aes256GcmEncryptContext(const key256 &key, std::span<const std::byte> nonce)
    : impl_(std::make_unique<Impl>(make_aes256_gcm_context()))
{
	initialize_encrypt_context(impl_->context.get(), key, nonce);
}

Aes256GcmEncryptContext::~Aes256GcmEncryptContext() = default;

Aes256GcmEncryptContext::Aes256GcmEncryptContext(Aes256GcmEncryptContext &&) noexcept = default;

Aes256GcmEncryptContext &Aes256GcmEncryptContext::operator=(Aes256GcmEncryptContext &&) noexcept = default;

void Aes256GcmEncryptContext::update_aad(std::span<const std::byte> aad)
{
	update_aad_impl(impl_->context.get(), aad);
}

bytes Aes256GcmEncryptContext::update(std::span<const std::byte> plaintext)
{
	const int plaintext_size = int_size(plaintext.size(), "plaintext");
	bytes ciphertext(plaintext.size());
	if (plaintext_size == 0)
	{
		return ciphertext;
	}

	int ciphertext_size = 0;
	if (EVP_EncryptUpdate(impl_->context.get(), openssl_data(ciphertext.data()), &ciphertext_size, openssl_data(plaintext), plaintext_size) != 1)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}
	if (ciphertext_size != plaintext_size)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}
	return ciphertext;
}

std::array<std::byte, 16> Aes256GcmEncryptContext::finalize()
{
	std::array<std::byte, 1> final_buffer{};
	int final_size = 0;
	if (EVP_EncryptFinal_ex(impl_->context.get(), openssl_data(final_buffer.data()), &final_size) != 1)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}
	if (final_size != 0)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}

	std::array<std::byte, 16> tag{};
	if (EVP_CIPHER_CTX_ctrl(impl_->context.get(), EVP_CTRL_GCM_GET_TAG, static_cast<int>(tag.size()), openssl_data(tag.data())) != 1)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}
	impl_.reset();
	return tag;
}

Aes256GcmDecryptContext::Aes256GcmDecryptContext(const key256 &key, std::span<const std::byte> nonce)
    : impl_(std::make_unique<Impl>(make_aes256_gcm_context()))
{
	initialize_decrypt_context(impl_->context.get(), key, nonce);
}

Aes256GcmDecryptContext::~Aes256GcmDecryptContext() = default;

Aes256GcmDecryptContext::Aes256GcmDecryptContext(Aes256GcmDecryptContext &&) noexcept = default;

Aes256GcmDecryptContext &Aes256GcmDecryptContext::operator=(Aes256GcmDecryptContext &&) noexcept = default;

void Aes256GcmDecryptContext::update_aad(std::span<const std::byte> aad)
{
	update_aad_impl(impl_->context.get(), aad);
}

bytes Aes256GcmDecryptContext::update(std::span<const std::byte> ciphertext)
{
	const int ciphertext_size = int_size(ciphertext.size(), "ciphertext");
	bytes plaintext(ciphertext.size());
	if (ciphertext_size == 0)
	{
		return plaintext;
	}

	int plaintext_size = 0;
	if (EVP_DecryptUpdate(impl_->context.get(), openssl_data(plaintext.data()), &plaintext_size, openssl_data(ciphertext), ciphertext_size) != 1)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}
	if (plaintext_size != ciphertext_size)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}
	return plaintext;
}

bytes Aes256GcmDecryptContext::finalize(std::span<const std::byte> tag)
{
	if (tag.size() != 16)
	{
		throw anosecurekit::error(anosecurekit::error_code::invalid_input, "AES-256-GCM tag must be 16 bytes");
	}

	std::array<std::byte, 16> tag_copy{};
	std::copy(tag.begin(), tag.end(), tag_copy.begin());
	if (EVP_CIPHER_CTX_ctrl(impl_->context.get(), EVP_CTRL_GCM_SET_TAG, static_cast<int>(tag_copy.size()), openssl_data(tag_copy.data())) != 1)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}

	std::array<std::byte, 1> final_buffer{};
	int final_size = 0;
	if (EVP_DecryptFinal_ex(impl_->context.get(), openssl_data(final_buffer.data()), &final_size) != 1)
	{
		impl_.reset();
		throw_aead_authentication_failed();
	}
	if (final_size < 0 || static_cast<std::size_t>(final_size) > final_buffer.size())
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}

	bytes trailing(static_cast<std::size_t>(final_size));
	std::copy_n(final_buffer.begin(), trailing.size(), trailing.begin());
	impl_.reset();
	return trailing;
}

digest256 sha256(std::span<const std::byte> input)
{
	DigestContext context(EVP_MD_CTX_new(), EVP_MD_CTX_free);
	const EVP_MD *digest = EVP_sha256();
	if (context == nullptr || digest == nullptr)
	{
		throw_backend_failure("OpenSSL SHA-256 operation failed");
	}

	if (EVP_DigestInit_ex(context.get(), digest, nullptr) != 1)
	{
		throw_backend_failure("OpenSSL SHA-256 operation failed");
	}

	const bool digest_updated = input.empty() || EVP_DigestUpdate(context.get(), input.data(), input.size()) == 1;
	if (!digest_updated)
	{
		throw_backend_failure("OpenSSL SHA-256 operation failed");
	}

	digest256 output{};
	unsigned int output_size = 0;
	auto *output_data = reinterpret_cast<unsigned char *>(output.data());
	if (EVP_DigestFinal_ex(context.get(), output_data, &output_size) != 1)
	{
		throw_backend_failure("OpenSSL SHA-256 operation failed");
	}

	if (output_size != static_cast<unsigned int>(output.size()))
	{
		throw_backend_failure("OpenSSL SHA-256 operation failed");
	}

	return output;
}

bytes hkdf_sha256(std::span<const std::byte> key_material, std::span<const std::byte> salt, std::span<const std::byte> info, std::size_t output_size)
{
	bytes output(output_size);
	if (output.empty())
	{
		return output;
	}

	Kdf kdf(EVP_KDF_fetch(nullptr, "HKDF", nullptr), EVP_KDF_free);
	if (kdf == nullptr)
	{
		throw_backend_failure("OpenSSL HKDF-SHA-256 operation failed");
	}

	KdfContext context(EVP_KDF_CTX_new(kdf.get()), EVP_KDF_CTX_free);
	if (context == nullptr)
	{
		throw_backend_failure("OpenSSL HKDF-SHA-256 operation failed");
	}

	char digest_name[] = "SHA256";
	int mode = EVP_KDF_HKDF_MODE_EXTRACT_AND_EXPAND;
	std::byte empty_octet{};
	auto *key_data = const_cast<std::byte *>(key_material.empty() ? &empty_octet : key_material.data());

	std::array<OSSL_PARAM, 6> params{};
	std::size_t param_count = 0;
	params[param_count++] = OSSL_PARAM_construct_utf8_string(OSSL_KDF_PARAM_DIGEST, digest_name, 0);
	params[param_count++] = OSSL_PARAM_construct_int(OSSL_KDF_PARAM_MODE, &mode);
	params[param_count++] = OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_KEY, key_data, key_material.size());
	if (!salt.empty())
	{
		params[param_count++] = OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_SALT, const_cast<std::byte *>(salt.data()), salt.size());
	}
	if (!info.empty())
	{
		params[param_count++] = OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_INFO, const_cast<std::byte *>(info.data()), info.size());
	}
	params[param_count] = OSSL_PARAM_construct_end();

	auto *output_data = reinterpret_cast<unsigned char *>(output.data());
	if (EVP_KDF_derive(context.get(), output_data, output.size(), params.data()) != 1)
	{
		throw_backend_failure("OpenSSL HKDF-SHA-256 operation failed");
	}

	return output;
}

digest256 hmac_sha256(std::span<const std::byte> key, std::span<const std::byte> input)
{
	digest256 output{};
	std::size_t output_size = 0;
	const std::byte empty_octet{};

	auto *output_data = reinterpret_cast<unsigned char *>(output.data());
	const auto *key_data = key.empty() ? &empty_octet : key.data();
	const auto *input_data = reinterpret_cast<const unsigned char *>(input.empty() ? &empty_octet : input.data());

	if (EVP_Q_mac(
	        nullptr,
	        "HMAC",
	        nullptr,
	        "SHA256",
	        nullptr,
	        key_data,
	        key.size(),
	        input_data,
	        input.size(),
	        output_data,
	        output.size(),
	        &output_size) == nullptr)
	{
		throw_backend_failure("OpenSSL HMAC-SHA-256 operation failed");
	}

	if (output_size != output.size())
	{
		throw_backend_failure("OpenSSL HMAC-SHA-256 operation failed");
	}

	return output;
}

bytes random_bytes(std::size_t size)
{
	bytes output(size);
	if (output.empty())
	{
		return output;
	}

	fill_random(reinterpret_cast<unsigned char *>(output.data()), output.size(), false);
	return output;
}

key256 generate_key()
{
	key256 key{};
	fill_random(reinterpret_cast<unsigned char *>(key.data()), key.size(), true);
	return key;
}

key256 scrypt_key(std::span<const std::byte> password, std::span<const std::byte> salt, const ScryptParams &params)
{
	key256 key{};
	if (EVP_PBE_scrypt(
	        reinterpret_cast<const char *>(password.data()),
	        password.size(),
	        openssl_data(salt),
	        salt.size(),
	        params.n,
	        params.r,
	        params.p,
	        params.max_memory,
	        openssl_data(key.data()),
	        key.size()) != 1)
	{
		internal::secure_wipe(key);
		throw_backend_failure("OpenSSL scrypt operation failed");
	}
	return key;
}

Aes256GcmResult aes256_gcm_encrypt(
    std::span<const std::byte> plaintext,
    const key256 &key,
    std::span<const std::byte> nonce,
    std::span<const std::byte> aad)
{
	const int plaintext_size = int_size(plaintext.size(), "plaintext");
	Aes256GcmResult output{};
	output.ciphertext.resize(plaintext.size());

	CipherContext context = make_aes256_gcm_context();
	initialize_encrypt_context(context.get(), key, nonce);

	update_aad_impl(context.get(), aad);

	int ciphertext_size = 0;
	if (plaintext_size > 0 &&
	    EVP_EncryptUpdate(context.get(), openssl_data(output.ciphertext.data()), &ciphertext_size, openssl_data(plaintext), plaintext_size) != 1)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}

	int final_size = 0;
	std::array<std::byte, 1> final_buffer{};
	std::byte *final_output = output.ciphertext.empty() ? final_buffer.data() : output.ciphertext.data() + ciphertext_size;
	if (EVP_EncryptFinal_ex(context.get(), openssl_data(final_output), &final_size) != 1)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}
	if (ciphertext_size + final_size != plaintext_size)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}
	if (EVP_CIPHER_CTX_ctrl(context.get(), EVP_CTRL_GCM_GET_TAG, static_cast<int>(output.tag.size()), openssl_data(output.tag.data())) != 1)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}

	return output;
}

bytes aes256_gcm_decrypt(
    std::span<const std::byte> ciphertext,
    std::span<const std::byte> tag,
    const key256 &key,
    std::span<const std::byte> nonce,
    std::span<const std::byte> aad)
{
	if (tag.size() != 16)
	{
		throw anosecurekit::error(anosecurekit::error_code::invalid_input, "AES-256-GCM tag must be 16 bytes");
	}

	const int ciphertext_size = int_size(ciphertext.size(), "ciphertext");
	bytes plaintext(ciphertext.size());

	CipherContext context = make_aes256_gcm_context();
	initialize_decrypt_context(context.get(), key, nonce);

	update_aad_impl(context.get(), aad);

	int plaintext_size = 0;
	if (ciphertext_size > 0 &&
	    EVP_DecryptUpdate(context.get(), openssl_data(plaintext.data()), &plaintext_size, openssl_data(ciphertext), ciphertext_size) != 1)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}

	std::array<std::byte, 16> tag_copy{};
	std::copy(tag.begin(), tag.end(), tag_copy.begin());
	if (EVP_CIPHER_CTX_ctrl(context.get(), EVP_CTRL_GCM_SET_TAG, static_cast<int>(tag_copy.size()), openssl_data(tag_copy.data())) != 1)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}

	std::array<std::byte, 1> final_buffer{};
	std::byte *final_output = plaintext.empty() ? final_buffer.data() : plaintext.data() + plaintext_size;
	int final_size = 0;
	if (EVP_DecryptFinal_ex(context.get(), openssl_data(final_output), &final_size) != 1)
	{
		internal::secure_wipe(plaintext);
		throw_authentication_failed();
	}
	if (plaintext_size + final_size != ciphertext_size)
	{
		throw_backend_failure("OpenSSL AES-256-GCM operation failed");
	}

	return plaintext;
}

} // namespace anosecurekit::detail::crypto_backend
