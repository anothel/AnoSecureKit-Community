// SPDX-License-Identifier: MPL-2.0
#include "../../src/cli/commands.hpp"
#include "anosecurekit/anosecurekit.hpp"
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <unistd.h>

namespace
{
std::size_t descriptors()
{
	return static_cast<std::size_t>(std::distance(std::filesystem::directory_iterator("/proc/self/fd"), std::filesystem::directory_iterator{}));
}
} // namespace
int main(int argc, char **argv)
{
	if (argc < 2)
		return 2;
	const auto before = descriptors();
	int status = 0;
	try
	{
		const std::string mode = argv[1];
		if (mode == "cli" && std::getenv("ASK_IO_STDIN") && *std::getenv("ASK_IO_STDIN") &&
		    std::getenv("ASK_IO_FAULT") && std::string(std::getenv("ASK_IO_FAULT")) == "read")
		{
			// stdio-backed cin may use hidden libc reads: inject its observable
			// failure state directly, confined to this driver.
			std::ofstream(std::getenv("ASK_IO_MARKER")).put('1');
			std::cin.setstate(std::ios::badbit);
		}
		if (mode == "cli")
			status = anosecurekit::cli::run(argc - 1, argv + 1);
		else
		{
			if (argc != 5)
				return 2;
			const anosecurekit::key256 key{};
			const anosecurekit::bytes password{std::byte{'p'}};
			if (mode == "seal")
				anosecurekit::seal_file(argv[2], argv[3], key);
			else if (mode == "open")
				anosecurekit::open_file(argv[2], argv[3], key);
			else if (mode == "seal-password")
				anosecurekit::seal_file_with_password(argv[2], argv[3], password);
			else if (mode == "open-password")
				anosecurekit::open_file_with_password(argv[2], argv[3], password);
			else
				return 2;
		}
	}
	catch (const anosecurekit::error &error)
	{
		std::cerr << error.what() << '\n';
		status = error.code() == anosecurekit::error_code::backend_failure ? 1 : (error.code() == anosecurekit::error_code::invalid_input ? 5 : 4);
	}
	if (descriptors() != before)
	{
		std::cerr << "descriptor leak\n";
		return 3;
	}
	return status;
}
