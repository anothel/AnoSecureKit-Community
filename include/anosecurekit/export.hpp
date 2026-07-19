// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_EXPORT_HPP_
#define ANOSECUREKIT_EXPORT_HPP_

#if defined(ANOSECUREKIT_SHARED)
#if defined(_WIN32)
#if defined(ANOSECUREKIT_BUILDING_LIBRARY)
#define ANOSECUREKIT_API __declspec(dllexport)
#else
#define ANOSECUREKIT_API __declspec(dllimport)
#endif
#elif defined(__GNUC__) || defined(__clang__)
#define ANOSECUREKIT_API __attribute__((visibility("default")))
#else
#define ANOSECUREKIT_API
#endif
#else
#define ANOSECUREKIT_API
#endif

#endif // ANOSECUREKIT_EXPORT_HPP_
