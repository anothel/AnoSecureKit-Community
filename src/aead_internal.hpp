// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_SRC_AEAD_INTERNAL_HPP_
#define ANOSECUREKIT_SRC_AEAD_INTERNAL_HPP_

#include <algorithm>
#include <array>
#include <cstddef>
#include <limits>
#include <span>
#include <string>

#include "anosecurekit/error.hpp"
#include "anosecurekit/types.hpp"

namespace anosecurekit::internal_aead
{

inline constexpr std::array<std::byte, 4> kMagic{std::byte{'S'}, std::byte{'K'}, std::byte{'T'}, std::byte{'1'}};
inline constexpr std::byte kVersion{0x01};
inline constexpr std::size_t kMagicSize = kMagic.size();
inline constexpr std::size_t kVersionSize = 1;
inline constexpr std::size_t kHeaderSize = kMagicSize + kVersionSize;
inline constexpr std::size_t kNonceSize = 12;
inline constexpr std::size_t kPrefixSize = kHeaderSize + kNonceSize;
inline constexpr std::size_t kTagSize = 16;
inline constexpr std::size_t kOverhead = kPrefixSize + kTagSize;

[[noreturn]] inline void throw_invalid_packet()
{
	throw error(error_code::invalid_packet, "Invalid AEAD packet");
}

[[noreturn]] inline void throw_invalid_input(const char *message)
{
	throw error(error_code::invalid_input, message);
}

inline void check_update_size(std::size_t size, const char *name)
{
	if (size > static_cast<std::size_t>(std::numeric_limits<int>::max()))
	{
		std::string message(name);
		message.append(" exceeds backend update limit");
		throw error(error_code::invalid_input, std::move(message));
	}
}

inline std::array<std::byte, kHeaderSize> make_header()
{
	std::array<std::byte, kHeaderSize> header{};
	std::copy(kMagic.begin(), kMagic.end(), header.begin());
	header[kMagicSize] = kVersion;
	return header;
}

inline bytes make_packet_prefix(std::span<const std::byte> nonce)
{
	if (nonce.size() != kNonceSize)
	{
		throw error(error_code::backend_failure, "AES-256-GCM operation failed");
	}

	bytes prefix(kPrefixSize);
	const auto header = make_header();
	std::copy(header.begin(), header.end(), prefix.begin());
	std::copy(nonce.begin(), nonce.end(), prefix.begin() + kHeaderSize);
	return prefix;
}

inline void require_valid_prefix(std::span<const std::byte> packet_prefix)
{
	if (packet_prefix.size() != kPrefixSize)
	{
		throw_invalid_packet();
	}

	if (!std::equal(kMagic.begin(), kMagic.end(), packet_prefix.begin()))
	{
		throw_invalid_packet();
	}

	if (packet_prefix[kMagicSize] != kVersion)
	{
		throw_invalid_packet();
	}
}

inline void require_valid_packet(std::span<const std::byte> packet)
{
	if (packet.size() < kOverhead)
	{
		throw_invalid_packet();
	}

	require_valid_prefix(packet.first(kPrefixSize));
}

} // namespace anosecurekit::internal_aead

#endif // ANOSECUREKIT_SRC_AEAD_INTERNAL_HPP_
