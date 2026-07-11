// SPDX-License-Identifier: MPL-2.0
#include "anosecurekit/packet_stream.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <span>

#include "aead_internal.hpp"
#include "backend/crypto_backend.hpp"
#include "internal/secure_wipe.hpp"

namespace
{

enum class packet_stream_phase
{
	ready,
	active,
	finished,
};

anosecurekit::bytes copy_bytes(std::span<const std::byte> input)
{
	return anosecurekit::bytes(input.begin(), input.end());
}

} // namespace

namespace anosecurekit
{

struct packet_encryptor::impl
{
	impl(const key256 &input_key, std::span<const std::byte> input_aad)
	    : key(input_key),
	      aad(copy_bytes(input_aad))
	{
		internal_aead::check_update_size(aad.size(), "AAD");
	}

	~impl()
	{
		internal::secure_wipe(key);
		internal::secure_wipe(aad);
	}

	key256 key{};
	bytes aad;
	std::unique_ptr<detail::crypto_backend::Aes256GcmEncryptContext> context;
	packet_stream_phase phase = packet_stream_phase::ready;
};

struct packet_decryptor::impl
{
	impl(const key256 &input_key, std::span<const std::byte> input_aad)
	    : key(input_key),
	      aad(copy_bytes(input_aad))
	{
		internal_aead::check_update_size(aad.size(), "AAD");
	}

	~impl()
	{
		internal::secure_wipe(key);
		internal::secure_wipe(aad);
	}

	key256 key{};
	bytes aad;
	std::unique_ptr<detail::crypto_backend::Aes256GcmDecryptContext> context;
	packet_stream_phase phase = packet_stream_phase::ready;
};

packet_encryptor::packet_encryptor(const key256 &key, std::span<const std::byte> aad) : impl_(std::make_unique<impl>(key, aad))
{
}

packet_encryptor::~packet_encryptor() = default;

packet_encryptor::packet_encryptor(packet_encryptor &&other) noexcept = default;

packet_encryptor &packet_encryptor::operator=(packet_encryptor &&other) noexcept = default;

bytes packet_encryptor::begin()
{
	if (impl_ == nullptr)
	{
		internal_aead::throw_invalid_input("packet encryptor has no state");
	}

	if (impl_->phase != packet_stream_phase::ready)
	{
		internal_aead::throw_invalid_input("packet encryptor begin() may only be called once");
	}

	bytes nonce = detail::crypto_backend::random_bytes(internal_aead::kNonceSize);

	const auto header = internal_aead::make_header();
	impl_->context = std::make_unique<detail::crypto_backend::Aes256GcmEncryptContext>(impl_->key, nonce);
	impl_->context->update_aad(header);
	impl_->context->update_aad(impl_->aad);

	impl_->phase = packet_stream_phase::active;
	return internal_aead::make_packet_prefix(nonce);
}

bytes packet_encryptor::update(std::span<const std::byte> plaintext)
{
	if (impl_ == nullptr)
	{
		internal_aead::throw_invalid_input("packet encryptor has no state");
	}

	if (impl_->phase != packet_stream_phase::active)
	{
		internal_aead::throw_invalid_input("packet encryptor update() requires begin() before finalize()");
	}

	return impl_->context->update(plaintext);
}

bytes packet_encryptor::finalize()
{
	if (impl_ == nullptr)
	{
		internal_aead::throw_invalid_input("packet encryptor has no state");
	}

	if (impl_->phase != packet_stream_phase::active)
	{
		internal_aead::throw_invalid_input("packet encryptor finalize() requires begin() exactly once");
	}

	const std::array<std::byte, internal_aead::kTagSize> tag_array = impl_->context->finalize();
	bytes tag(tag_array.begin(), tag_array.end());

	impl_->context.reset();
	impl_->phase = packet_stream_phase::finished;
	return tag;
}

packet_decryptor::packet_decryptor(const key256 &key, std::span<const std::byte> aad) : impl_(std::make_unique<impl>(key, aad))
{
}

packet_decryptor::~packet_decryptor() = default;

packet_decryptor::packet_decryptor(packet_decryptor &&other) noexcept = default;

packet_decryptor &packet_decryptor::operator=(packet_decryptor &&other) noexcept = default;

void packet_decryptor::begin(std::span<const std::byte> packet_prefix)
{
	if (impl_ == nullptr)
	{
		internal_aead::throw_invalid_input("packet decryptor has no state");
	}

	if (impl_->phase != packet_stream_phase::ready)
	{
		internal_aead::throw_invalid_input("packet decryptor begin() may only be called once");
	}

	internal_aead::require_valid_prefix(packet_prefix);

	const std::span<const std::byte> header = packet_prefix.first(internal_aead::kHeaderSize);
	const std::span<const std::byte> nonce = packet_prefix.last(internal_aead::kNonceSize);

	impl_->context = std::make_unique<detail::crypto_backend::Aes256GcmDecryptContext>(impl_->key, nonce);
	impl_->context->update_aad(header);
	impl_->context->update_aad(impl_->aad);

	impl_->phase = packet_stream_phase::active;
}

bytes packet_decryptor::update(std::span<const std::byte> ciphertext)
{
	if (impl_ == nullptr)
	{
		internal_aead::throw_invalid_input("packet decryptor has no state");
	}

	if (impl_->phase != packet_stream_phase::active)
	{
		internal_aead::throw_invalid_input("packet decryptor update() requires begin() before finalize()");
	}

	return impl_->context->update(ciphertext);
}

bytes packet_decryptor::finalize(std::span<const std::byte> tag)
{
	if (impl_ == nullptr)
	{
		internal_aead::throw_invalid_input("packet decryptor has no state");
	}

	if (impl_->phase != packet_stream_phase::active)
	{
		internal_aead::throw_invalid_input("packet decryptor finalize() requires begin() exactly once");
	}

	if (tag.size() != internal_aead::kTagSize)
	{
		impl_->context.reset();
		impl_->phase = packet_stream_phase::finished;
		internal_aead::throw_invalid_packet();
	}

	bytes trailing;
	try
	{
		trailing = impl_->context->finalize(tag);
	}
	catch (...)
	{
		impl_->context.reset();
		impl_->phase = packet_stream_phase::finished;
		throw;
	}

	impl_->context.reset();
	impl_->phase = packet_stream_phase::finished;
	return trailing;
}

} // namespace anosecurekit
