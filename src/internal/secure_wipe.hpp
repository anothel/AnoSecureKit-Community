// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_SRC_INTERNAL_SECURE_WIPE_HPP_
#define ANOSECUREKIT_SRC_INTERNAL_SECURE_WIPE_HPP_

#include <array>
#include <cstddef>
#include <span>

#include "anosecurekit/export.hpp"
#include "anosecurekit/types.hpp"

namespace anosecurekit::internal
{

void secure_wipe(std::span<std::byte> data) noexcept;

template <std::size_t Size>
inline void secure_wipe(std::array<std::byte, Size> &data) noexcept
{
	secure_wipe(std::span<std::byte>(data));
}

inline void secure_wipe(bytes &data) noexcept
{
	secure_wipe(std::span<std::byte>(data));
}

class wipe_on_exit
{
public:
	explicit wipe_on_exit(std::span<std::byte> data) noexcept : data_(data)
	{
	}

	wipe_on_exit(const wipe_on_exit &) = delete;
	wipe_on_exit &operator=(const wipe_on_exit &) = delete;

	~wipe_on_exit()
	{
		secure_wipe(data_);
	}

private:
	std::span<std::byte> data_;
};

} // namespace anosecurekit::internal

#endif // ANOSECUREKIT_SRC_INTERNAL_SECURE_WIPE_HPP_
