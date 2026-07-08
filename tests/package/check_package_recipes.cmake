# SPDX-License-Identifier: MPL-2.0
if(NOT DEFINED ANOSECUREKIT_PACKAGE_CHECK_ROOT)
  message(FATAL_ERROR "ANOSECUREKIT_PACKAGE_CHECK_ROOT is required")
endif()

if(NOT DEFINED ANOSECUREKIT_PROJECT_NAME OR ANOSECUREKIT_PROJECT_NAME STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_PROJECT_NAME is required")
endif()

if(NOT DEFINED ANOSECUREKIT_PROJECT_VERSION OR ANOSECUREKIT_PROJECT_VERSION STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_PROJECT_VERSION is required")
endif()

if(NOT ANOSECUREKIT_PROJECT_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+$")
  message(FATAL_ERROR "Project version is not SemVer x.y.z: ${ANOSECUREKIT_PROJECT_VERSION}")
endif()

set(_anosecurekit_release_asset_dir "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/release-assets")
set(_anosecurekit_checksum_file "${_anosecurekit_release_asset_dir}/SHA256SUMS.txt")
set(_anosecurekit_source_name "${ANOSECUREKIT_PROJECT_NAME}-${ANOSECUREKIT_PROJECT_VERSION}-source.tar.gz")
set(_anosecurekit_source_archive "${_anosecurekit_release_asset_dir}/${_anosecurekit_source_name}")

if(NOT EXISTS "${_anosecurekit_checksum_file}")
  message(FATAL_ERROR "SHA256SUMS.txt not found: ${_anosecurekit_checksum_file}")
endif()
if(NOT EXISTS "${_anosecurekit_source_archive}")
  message(FATAL_ERROR "Source release archive not found: ${_anosecurekit_source_archive}")
endif()

file(STRINGS "${_anosecurekit_checksum_file}" _anosecurekit_checksum_lines)
set(_anosecurekit_source_sha256 "")
foreach(_anosecurekit_checksum_line IN LISTS _anosecurekit_checksum_lines)
  if(_anosecurekit_checksum_line MATCHES "^([0-9a-f]+)  ${_anosecurekit_source_name}$")
    set(_anosecurekit_source_sha256 "${CMAKE_MATCH_1}")
  endif()
endforeach()
if(_anosecurekit_source_sha256 STREQUAL "")
  message(FATAL_ERROR "SHA256SUMS.txt has no entry for ${_anosecurekit_source_name}")
endif()
string(LENGTH "${_anosecurekit_source_sha256}" _anosecurekit_source_sha256_length)
if(NOT _anosecurekit_source_sha256_length EQUAL 64)
  message(FATAL_ERROR "Source archive SHA256 has wrong length")
endif()

file(SHA256 "${_anosecurekit_source_archive}" _anosecurekit_actual_sha256)
if(NOT _anosecurekit_actual_sha256 STREQUAL _anosecurekit_source_sha256)
  message(FATAL_ERROR "Source archive SHA256 does not match SHA256SUMS.txt")
endif()
file(SHA512 "${_anosecurekit_source_archive}" _anosecurekit_source_sha512)

set(_anosecurekit_release_url
  "https://github.com/anothel/anosecurekit/releases/download/v${ANOSECUREKIT_PROJECT_VERSION}/${_anosecurekit_source_name}")
set(_anosecurekit_recipe_dir "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/package-recipes")
file(REMOVE_RECURSE "${_anosecurekit_recipe_dir}")
file(MAKE_DIRECTORY
  "${_anosecurekit_recipe_dir}/homebrew"
  "${_anosecurekit_recipe_dir}/conan"
  "${_anosecurekit_recipe_dir}/vcpkg")

set(_anosecurekit_homebrew_formula "${_anosecurekit_recipe_dir}/homebrew/anosecurekit.rb")
file(WRITE "${_anosecurekit_homebrew_formula}"
"class Anosecurekit < Formula
  desc \"Small C++20 security utility library\"
  homepage \"https://github.com/anothel/anosecurekit\"
  url \"${_anosecurekit_release_url}\"
  sha256 \"${_anosecurekit_source_sha256}\"
  license \"MPL-2.0\"

  depends_on \"cmake\" => :build
  depends_on \"openssl@3\"

  def install
    system \"cmake\", \"-S\", \".\", \"-B\", \"build\",
      \"-DBUILD_TESTING=OFF\",
      \"-DANOSECUREKIT_BUILD_TESTS=OFF\",
      \"-DOPENSSL_ROOT_DIR=#{Formula[\"openssl@3\"].opt_prefix}\",
      *std_cmake_args
    system \"cmake\", \"--build\", \"build\"
    system \"cmake\", \"--install\", \"build\"
  end

  test do
    assert_match \"anosecurekit ${ANOSECUREKIT_PROJECT_VERSION}\", shell_output(\"#{bin}/anosecurekit --version\")
  end
end
")

set(_anosecurekit_conan_recipe "${_anosecurekit_recipe_dir}/conan/conanfile.py")
file(WRITE "${_anosecurekit_conan_recipe}"
"from os.path import join

from conan import ConanFile
from conan.tools.cmake import CMake, CMakeDeps, CMakeToolchain, cmake_layout
from conan.tools.files import copy, get


class AnoSecureKitConan(ConanFile):
    name = \"anosecurekit\"
    version = \"${ANOSECUREKIT_PROJECT_VERSION}\"
    license = \"MPL-2.0\"
    url = \"https://github.com/anothel/anosecurekit\"
    description = \"Small C++20 security utility library\"
    settings = \"os\", \"compiler\", \"build_type\", \"arch\"
    options = {\"shared\": [True, False], \"with_cli\": [True, False]}
    default_options = {\"shared\": False, \"with_cli\": True}

    def requirements(self):
        self.requires(\"openssl/[>=3.0 <4]\")

    def layout(self):
        cmake_layout(self)

    def source(self):
        get(self, url=\"${_anosecurekit_release_url}\", sha256=\"${_anosecurekit_source_sha256}\", strip_root=True)

    def generate(self):
        deps = CMakeDeps(self)
        deps.generate()
        tc = CMakeToolchain(self)
        tc.variables[\"BUILD_TESTING\"] = False
        tc.variables[\"ANOSECUREKIT_BUILD_TESTS\"] = False
        tc.variables[\"ANOSECUREKIT_BUILD_CLI\"] = bool(self.options.with_cli)
        tc.variables[\"ANOSECUREKIT_INSTALL_CLI\"] = bool(self.options.with_cli)
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()
        copy(self, \"LICENSE\", src=self.source_folder, dst=join(self.package_folder, \"licenses\"))

    def package_info(self):
        self.cpp_info.libs = [\"anosecurekit\"]
")

set(_anosecurekit_vcpkg_json "${_anosecurekit_recipe_dir}/vcpkg/vcpkg.json")
file(WRITE "${_anosecurekit_vcpkg_json}"
"{
  \"name\": \"anosecurekit\",
  \"version\": \"${ANOSECUREKIT_PROJECT_VERSION}\",
  \"description\": \"Small C++20 security utility library\",
  \"homepage\": \"https://github.com/anothel/anosecurekit\",
  \"license\": \"MPL-2.0\",
  \"dependencies\": [
    \"openssl\",
    {
      \"name\": \"vcpkg-cmake\",
      \"host\": true
    },
    {
      \"name\": \"vcpkg-cmake-config\",
      \"host\": true
    }
  ]
}
")

set(_anosecurekit_vcpkg_portfile "${_anosecurekit_recipe_dir}/vcpkg/portfile.cmake")
file(WRITE "${_anosecurekit_vcpkg_portfile}"
"vcpkg_download_distfile(ARCHIVE
  URLS \"${_anosecurekit_release_url}\"
  FILENAME \"${_anosecurekit_source_name}\"
  SHA512 ${_anosecurekit_source_sha512})

vcpkg_extract_source_archive(
  SOURCE_PATH
  ARCHIVE \"\${ARCHIVE}\")

vcpkg_cmake_configure(
  SOURCE_PATH \"\${SOURCE_PATH}\"
  OPTIONS
    -DBUILD_TESTING=OFF
    -DANOSECUREKIT_BUILD_TESTS=OFF
    -DANOSECUREKIT_BUILD_CLI=OFF
    -DANOSECUREKIT_INSTALL_CLI=OFF)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/anosecurekit)
file(REMOVE_RECURSE \"\${CURRENT_PACKAGES_DIR}/debug/include\")
vcpkg_install_copyright(FILE_LIST \"\${SOURCE_PATH}/LICENSE\")
")

foreach(_anosecurekit_recipe IN ITEMS
    "${_anosecurekit_homebrew_formula}"
    "${_anosecurekit_conan_recipe}"
    "${_anosecurekit_vcpkg_json}"
    "${_anosecurekit_vcpkg_portfile}")
  if(NOT EXISTS "${_anosecurekit_recipe}")
    message(FATAL_ERROR "Package recipe was not generated: ${_anosecurekit_recipe}")
  endif()
  file(READ "${_anosecurekit_recipe}" _anosecurekit_recipe_text)
  string(FIND "${_anosecurekit_recipe_text}" "${ANOSECUREKIT_PROJECT_VERSION}" _anosecurekit_version_at)
  string(FIND "${_anosecurekit_recipe_text}" "${_anosecurekit_release_url}" _anosecurekit_url_at)
  if(_anosecurekit_version_at EQUAL -1)
    message(FATAL_ERROR "Package recipe is missing version ${ANOSECUREKIT_PROJECT_VERSION}: ${_anosecurekit_recipe}")
  endif()
  if(_anosecurekit_url_at EQUAL -1 AND NOT _anosecurekit_recipe MATCHES "vcpkg\\.json$")
    message(FATAL_ERROR "Package recipe is missing source URL: ${_anosecurekit_recipe}")
  endif()
endforeach()

file(READ "${_anosecurekit_homebrew_formula}" _anosecurekit_homebrew_text)
file(READ "${_anosecurekit_conan_recipe}" _anosecurekit_conan_text)
file(READ "${_anosecurekit_vcpkg_portfile}" _anosecurekit_vcpkg_text)

foreach(_anosecurekit_text IN ITEMS
    "${_anosecurekit_homebrew_text}"
    "${_anosecurekit_conan_text}")
  string(FIND "${_anosecurekit_text}" "${_anosecurekit_source_sha256}" _anosecurekit_sha_at)
  if(_anosecurekit_sha_at EQUAL -1)
    message(FATAL_ERROR "Package recipe is missing source SHA256")
  endif()
endforeach()

string(FIND "${_anosecurekit_vcpkg_text}" "${_anosecurekit_source_sha512}" _anosecurekit_sha512_at)
if(_anosecurekit_sha512_at EQUAL -1)
  message(FATAL_ERROR "vcpkg portfile is missing source SHA512")
endif()

file(WRITE "${_anosecurekit_recipe_dir}/README.md"
"# AnoSecureKit package recipe drafts

Generated by release-preflight from ${_anosecurekit_source_name} and SHA256SUMS.txt.
Publish these only after the matching GitHub Release assets are uploaded and
attested.
")
