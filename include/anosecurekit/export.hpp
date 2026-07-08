// SPDX-License-Identifier: MPL-2.0
#ifndef ANOSECUREKIT_EXPORT_HPP_
#define ANOSECUREKIT_EXPORT_HPP_

#if defined(_WIN32) && defined(ANOSECUREKIT_SHARED)
#if defined(ANOSECUREKIT_BUILDING_LIBRARY)
#define ANOSECUREKIT_API __declspec(dllexport)
#else
#define ANOSECUREKIT_API __declspec(dllimport)
#endif
#else
#define ANOSECUREKIT_API
#endif

#endif // ANOSECUREKIT_EXPORT_HPP_
