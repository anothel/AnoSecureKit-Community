// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_PACKET_STREAM_HPP_
#define ANOSECUREKIT_PACKET_STREAM_HPP_

#include <cstddef>
#include <memory>
#include <span>

#include "anosecurekit/export.hpp"
#include "anosecurekit/types.hpp"

namespace anosecurekit
{

class packet_encryptor
{
public:
	ANOSECUREKIT_API explicit packet_encryptor(const key256 &key, std::span<const std::byte> aad = {});
	ANOSECUREKIT_API ~packet_encryptor();

	ANOSECUREKIT_API packet_encryptor(packet_encryptor &&other) noexcept;
	ANOSECUREKIT_API packet_encryptor &operator=(packet_encryptor &&other) noexcept;

	packet_encryptor(const packet_encryptor &) = delete;
	packet_encryptor &operator=(const packet_encryptor &) = delete;

	ANOSECUREKIT_API bytes begin();
	ANOSECUREKIT_API bytes update(std::span<const std::byte> plaintext);
	ANOSECUREKIT_API bytes finalize();

private:
	struct impl;
	std::unique_ptr<impl> impl_;
};

class packet_decryptor
{
public:
	ANOSECUREKIT_API explicit packet_decryptor(const key256 &key, std::span<const std::byte> aad = {});
	ANOSECUREKIT_API ~packet_decryptor();

	ANOSECUREKIT_API packet_decryptor(packet_decryptor &&other) noexcept;
	ANOSECUREKIT_API packet_decryptor &operator=(packet_decryptor &&other) noexcept;

	packet_decryptor(const packet_decryptor &) = delete;
	packet_decryptor &operator=(const packet_decryptor &) = delete;

	ANOSECUREKIT_API void begin(std::span<const std::byte> packet_prefix);
	// Returns UNVERIFIED PLAINTEXT. Do not release, persist, or trust bytes from
	// update() until finalize() returns successfully.
	ANOSECUREKIT_API bytes update(std::span<const std::byte> ciphertext);
	ANOSECUREKIT_API bytes finalize(std::span<const std::byte> tag);

private:
	struct impl;
	std::unique_ptr<impl> impl_;
};

} // namespace anosecurekit

#endif // ANOSECUREKIT_PACKET_STREAM_HPP_
