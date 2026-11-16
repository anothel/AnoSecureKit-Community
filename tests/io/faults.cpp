// SPDX-License-Identifier: MPL-2.0
// Linux test-process interposition only. Never linked into a product target.
#include <cerrno>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <dlfcn.h>
#include <fcntl.h>
#include <string>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <unistd.h>

namespace
{
bool fired = false;
const char *setting(const char *name)
{
	const char *value = std::getenv(name);
	return value ? value : "";
}
bool owned(const char *path)
{
	return path && std::strstr(path, setting("ASK_IO_ROOT")) == path && *setting("ASK_IO_ROOT");
}
bool descriptor(int fd, bool temp_only = false)
{
	char name[64], path[4096];
	std::snprintf(name, sizeof(name), "/proc/self/fd/%d", fd);
	const auto size = ::readlink(name, path, sizeof(path) - 1);
	if (size < 0)
		return false;
	path[size] = 0;
	return owned(path) && (!temp_only || std::strstr(path, ".anosecurekit."));
}
bool hit(const char *operation, bool eligible)
{
	const bool persistent = !std::strcmp(setting("ASK_IO_FAULT"), "unlink-persistent") && !std::strcmp(operation, "unlink");
	if (!eligible || (!persistent && (fired || std::strcmp(setting("ASK_IO_FAULT"), operation))))
		return false;
	fired = true;
	// Raw syscalls avoid recursively invoking our own hooks.
	const long fd = ::syscall(SYS_openat, AT_FDCWD, setting("ASK_IO_MARKER"), O_WRONLY | O_CREAT, 0600);
	if (fd >= 0)
		::syscall(SYS_close, fd);
	errno = EIO;
	return true;
}
template <typename T>
T next(const char *name)
{
	return reinterpret_cast<T>(::dlsym(RTLD_NEXT, name));
}
bool directory(int fd)
{
	struct stat st{};
	return ::fstat(fd, &st) == 0 && S_ISDIR(st.st_mode);
}
} // namespace
extern "C" int open(const char *path, int flags, ...)
{
	// All callers under test create with 0600. Preserve arbitrary callers' mode.
	mode_t mode = 0;
	if (flags & O_CREAT)
	{
		va_list args;
		va_start(args, flags);
		mode = va_arg(args, int);
		va_end(args);
	}
	if (hit((flags & O_CREAT) ? "open" : "directory-open", owned(path)))
		return -1;
	return next<int (*)(const char *, int, ...)>("open")(path, flags, mode);
}
extern "C" FILE *fopen(const char *path, const char *mode)
{
	if (hit("input-open", owned(path)))
		return nullptr;
	return next<FILE *(*)(const char *, const char *)>("fopen")(path, mode);
}
extern "C" FILE *fopen64(const char *path, const char *mode)
{
	if (hit("input-open", owned(path)))
		return nullptr;
	return next<FILE *(*)(const char *, const char *)>("fopen64")(path, mode);
}
extern "C" FILE *fdopen(int fd, const char *mode)
{
	if (hit("fdopen", descriptor(fd)))
		return nullptr;
	return next<FILE *(*)(int, const char *)>("fdopen")(fd, mode);
}
extern "C" ssize_t read(int fd, void *data, size_t size)
{
	if (hit("read", !*setting("ASK_IO_STDIN") && descriptor(fd)))
		return -1;
	if (hit("read-eintr", descriptor(fd) || (fd == 0 && *setting("ASK_IO_STDIN"))))
	{
		errno = EINTR;
		return -1;
	}
	return next<ssize_t (*)(int, void *, size_t)>("read")(fd, data, size);
}
extern "C" ssize_t write(int fd, const void *data, size_t size)
{
	if (hit("write", descriptor(fd)))
		return -1;
	if (hit("write-eintr", descriptor(fd)))
	{
		errno = EINTR;
		return -1;
	}
	if (size > 1 && hit("short-write", descriptor(fd)))
		size = 1;
	return next<ssize_t (*)(int, const void *, size_t)>("write")(fd, data, size);
}
extern "C" size_t fwrite(const void *data, size_t size, size_t count, FILE *file)
{
	if (hit("fwrite", descriptor(::fileno(file))))
		return count ? count - 1 : 0;
	if (hit("fwrite-eintr", descriptor(::fileno(file))))
	{
		errno = EINTR;
		return 0;
	}
	return next<size_t (*)(const void *, size_t, size_t, FILE *)>("fwrite")(data, size, count, file);
}
extern "C" int fflush(FILE *file)
{
	if (file && hit("flush", descriptor(::fileno(file))))
		return EOF;
	return next<int (*)(FILE *)>("fflush")(file);
}
extern "C" int fsync(int fd)
{
	if (hit(directory(fd) ? "directory-sync" : "fsync", descriptor(fd)))
		return -1;
	return next<int (*)(int)>("fsync")(fd);
}
extern "C" int fclose(FILE *file)
{
	const bool fail = hit("fclose", descriptor(::fileno(file), true));
	const int result = next<int (*)(FILE *)>("fclose")(file);
	// Like Linux close errors: descriptor has been consumed even on error.
	return fail ? EOF : result;
}
extern "C" int close(int fd)
{
	const bool fail = hit(directory(fd) ? "directory-close" : "close", descriptor(fd));
	const int result = next<int (*)(int)>("close")(fd);
	return fail ? -1 : result;
}
extern "C" int link(const char *from, const char *to)
{
	if (hit("race", owned(from)))
	{
		const long fd = ::syscall(SYS_openat, AT_FDCWD, to, O_WRONLY | O_CREAT | O_EXCL, 0600);
		if (fd >= 0)
		{
			::syscall(SYS_write, fd, "sentinel", 8);
			::syscall(SYS_close, fd);
		}
	}
	if (hit("link", owned(from)))
		return -1;
	return next<int (*)(const char *, const char *)>("link")(from, to);
}
extern "C" int unlink(const char *path)
{
	if (hit("unlink", owned(path)))
		return -1;
	return next<int (*)(const char *)>("unlink")(path);
}
extern "C" int remove(const char *path)
{
	if (hit("unlink", owned(path)))
		return -1;
	return next<int (*)(const char *)>("remove")(path);
}
