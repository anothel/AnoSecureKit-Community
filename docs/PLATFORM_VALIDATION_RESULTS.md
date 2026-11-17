<!-- SPDX-License-Identifier: MPL-2.0 -->
# Platform compatibility validation — 2026-11-17

Baseline: latest origin/main `8a94c591f4d290107c698e6ab7e5598f53fd2b61`,
including merged Phase 6 PR #6. Branch: `codex/revival-platform-validation`.
Publication recommendation remains **NO-GO**. Phase 3 fuzzing and measured coverage
remain **DEFERRED**. Unavailable current security alert data is not cleared;
no security access workaround, alert dismissal, merge, release or tag is authorized.

## Test design

`Cli.WindowsConsole` runs only on native Windows. A detached Python worker
allocates its own genuine Win32 console, passes CONIN$ to the actual CLI, waits
for disabled echo/line/processed modes plus the prompt, and injects Unicode key
records using WriteConsoleInputW. Every case checks exact input-mode restoration,
exit status, secret-free stdout/stderr and absence of the sentinel in the console
screen buffer. Cases cover CR/LF, backspace, Ctrl-C/D/Z cancellation, empty input,
4096-byte acceptance and 4097-byte rejection. Matching password-file fixtures
prove the prompt's actual bytes authenticate, including explicit CP1252 and
CP437 conversions. No password contents are logged. Allocation failure fails
rather than passing a simulation. Worker and CTest outer timeouts bound hangs.

The separate native compatibility workflow builds a shared library and installed
CMake consumer from pinned pre-Phase-4 main
`0cb8bda7b6d96a11bd83228321707f83d62daa4c`. It runs the baseline executable,
freezes its SHA-256, removes the installed runtime and requires execution to fail,
then replaces only that runtime with the candidate installed library. It executes
the unchanged consumer and verifies its hash. No consumer relink or recompilation
occurs after freezing. The old consumer exercises public utility/crypto/file APIs,
packet object lifetimes, and a typed `anosecurekit::error` catch across the library
boundary. Current shared export allowlists run on the replacement build.
JSON evidence and frozen executables are retained as workflow artifacts.

The initially selected post-Phase-4 baseline produced a byte-identical library
on Linux, so the baseline was moved earlier to exercise the visibility correction.
This test is limited to matching architecture/compiler/STL/CRT/OpenSSL runtimes.
It does not establish ABI compatibility for arbitrary downstream layouts or
unsupported private symbols. A missing-runtime negative control checks loader
selection rather than inferring it from a successful launch alone.

## Verification status

Local Linux checks and native CI outcomes are recorded with immutable commits
below. Merely configuring Windows/macOS jobs does not count as native execution.
No production defect is asserted from static inspection or test scaffolding.

## Remaining limits

Windows ReadConsoleA uses the console input code page. Explicit single-byte code
pages are covered; UTF-8/multibyte editing, surrogate pairs, IME, physical keyboard
layout, ConPTY/remote consoles, console loss and forced termination are not covered.
Backspace removes one byte. Use password files for portable exact binary passwords.
No protection from terminal logging, memory inspection, swap/dumps or guaranteed
erasure is claimed. The harness does not prove recovery from external termination.

Existing filesystem fault-injection and stdout rollback limits still apply.
Platform evidence alone cannot authorize publication: all release blockers must
be separately resolved and a maintainer must authorize reconsidering NO-GO.

## Local execution evidence

Linux x86_64, GCC 14.2.0/libstdc++, OpenSSL 3.5.7, Python 3.12.14,
CMake 3.31.6, Ninja; clang-format 22.1.5. Implementation tree at
`70e5aa3fe4c2fa3c33e7e3a506eafbd9603d09ec`:

- Full static CTest: **134/134 PASS**.
- Full shared CTest: **134/134 PASS**; actual ELF export allowlist: **52 PASS**.
- External-provider parity: **134/134 PASS**, identical ordered inventory.
- Package/installed CLI/current and frozen-source consumers, current shared package:
  **PASS**. These rebuilt consumers are separate from the frozen-binary test.
- CLI documentation, document alignment, backend boundary, external hook, SPDX,
  legacy-name and formatting gates: **PASS**.
- Linux frozen binary replacement: **PASS**, including required missing-library
  failure. Consumer SHA-256 before/after:
  `c3a84f961ffcf6de1ed5ab919e737ce1b2258aa04214e80a109d4dd51f4a17ea`.
  Baseline DSO SHA-256:
  `ff9bb0e4e6e96ec5d97a8f08b17d5384e2cd81f745d3645f497f9dacab471694`;
  replacement DSO:
  `b89fa69917d31ef2493898623bd045982c8c27c59dfbe938e0ae169b4e99c8e9`.

Commands (repository root, repository tool directory added to PATH):

```sh
cmake -S . -B build -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON \
  -DCLANG_FORMAT_EXE=/tmp/platform-format/clang_format/data/bin/clang-format
cmake --build build --target check format-check package-check \
  external-backend-parity-check shared-package-check cli-docs-check \
  document-alignment-check backend-boundary-check external-backend-hook-check \
  spdx-check legacy-name-check -j4
cmake -S . -B build-shared -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON -DANOSECUREKIT_BUILD_TESTS=ON \
  -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON \
  -DFETCHCONTENT_SOURCE_DIR_GOOGLETEST="$PWD/build/_deps/googletest-src"
cmake --build build-shared --target check shared-symbol-check -j4
python3 tests/abi/check_binary_replacement.py . /tmp/platform-binary-final
```

Initial tool/setup failures: missing CMake on PATH; clang-format 19 disagreed with
the previously verified 22.1.5 style. Selecting the repository CMake and installing
22.1.5 resolved these without production edits. The binary test's temporary output
directory must be new on each run. Logs under `/tmp/platform-*` are local only.
Terminal git push had no credentials; the connected GitHub service published the
identical local tree `e148a898cc7b24e4b25f2166d1ea68480e70883d` as `70e5aa3`.

Independent read-only review checked console ctypes layout, loader selection and
frozen executable ownership. It identified boundary cases lacking a disclosure
sentinel and missing candidate shared package metadata coverage on macOS. Both
were strengthened before the implementation above was published. No confirmed
production compatibility defect has been found; no production behavior changed.

## Native execution evidence

PR: https://github.com/anothel/AnoSecureKit-Community/pull/7.

Windows frozen-binary replacement **PASS** in native job
[134112497468](https://github.com/anothel/AnoSecureKit-Community/actions/runs/44104338872/job/134112497468),
head `70e5aa3fe4c2fa3c33e7e3a506eafbd9603d09ec`, tested PR merge
`51e8d0f6286c83dc02ba28d0881dec39f116a671`. Windows Server 2025,
MSVC 19.51.36260.0, vcpkg OpenSSL 3.6.5. Baseline and replacement runs passed;
missing DLL control failed as required. All **55** actual DLL exports and both
current shared installed consumers passed. Frozen executable SHA-256:
`b073b61b8787457f57e8655d08e2015a3d85e9cbb8048ed9fd47f98d1538ded8`.
Baseline DLL:
`58f9916f70e8a2ca255f8e057fc86fcf8b5a523dbb5b02741f1380178b91cb01`;
replacement DLL:
`d353d8709e19c4a8459245f39416848c1c7e041df7ef2684b6050aebc7c88265`.
[Artifact 14338657953](https://github.com/anothel/AnoSecureKit-Community/actions/runs/44104338872/artifacts/14338657953)
retains the executable and JSON; archive digest
`7d98c24acb0231caab54b6e77e7a0b637cd75c5487e8a811c45920a00c098056`.

This Windows pass proves neither console behavior nor arbitrary CRT/compiler ABI
compatibility. Separate console and macOS shared-gate failures are investigated
below; a passing static macOS package job cannot clear a shared ABI failure.

Windows console regression first failed at `console-stage 3 wait` in native job
[134118869989](https://github.com/anothel/AnoSecureKit-Community/actions/runs/44106133041/job/134118869989).
The first two cases (CR and backspace) completed. Windows conhost discards an
injected LF key unless virtual-terminal input mode is enabled. The harness now
explicitly enables that supported mode for the LF case and checks its preservation
and restoration; other cases explicitly use ordinary console input. This is a
test-environment correction, not a production password-reader defect. No timeout
or assertion is waived. Native rerun results follow separately.

The native macOS 26 ARM64/AppleClang 21 export diagnostic in job
[134120623541](https://github.com/anothel/AnoSecureKit-Community/actions/runs/44106630951/job/134120623541)
identified **49 unique public function names**, with all function counts intact;
exception RTTI/name/vtable were absent from the exported inventory. The original
ELF-oriented gate required those three exports and rejected the dylib. Apple ARM64
uses nonunique compiler-emitted RTTI. The gate now selects an exact ARM64 Mach-O
allowlist using `lipo -archs` on the actual library; ELF retains 52 exports and
other architectures retain their existing policy. No arbitrary exports are allowed
and no runtime class layout, signature or destructor is changed to satisfy a gate.
A recorded real-output fixture reproduces the old rejection and passes the new
49-symbol policy locally; this replay is **static/simulated validator evidence**,
not native library execution. Native frozen-binary typed catches remain mandatory.
The follow-up lane pins supported macOS 15; macOS-latest CTest/package coverage is
retained in the existing workflow. Thin ARM64 evidence does not prove universal
binaries or Intel C++ ABI compatibility.

Native macOS 15.8.2 ARM64/AppleClang 17.0.0.17000013/OpenSSL 3.5.9
**PASS** in job
[134130316225](https://github.com/anothel/AnoSecureKit-Community/actions/runs/44109330056/job/134130316225),
head `f5e68f6e5c105414600aa02a3f10fcf7a9161487`, tested PR merge
`f73828f28a196a261ec05cf07bb2d5e2656c5a9a`. The unchanged old binary passed
before and after replacement, and the missing-library control failed. **49**
actual Mach-O exports and both current shared installed consumers passed.
Unrestricted `nm -m` confirms `__ZTIN12anosecurekit5errorE`,
`__ZTSN12anosecurekit5errorE` and `__ZTVN12anosecurekit5errorE` exist as
non-external (formerly private external) metadata. The typed catch succeeds
without exporting those descriptors or changing the public class.
Frozen consumer SHA-256:
`7d2c00743a09c81c8eb724877d39b6f4fe1872ee76ce6e22ff1608028947eaf0`.
Baseline dylib:
`d9ed3ea32b06cbf451088952cc078194254fb1fd6ec3ce7a15f68f239ecd126d`;
replacement dylib:
`a54003ee9e24eec33f0625397743d9405abfc42447fe206ae1818110f9b0af29`.
[Artifact 14340560757](https://github.com/anothel/AnoSecureKit-Community/actions/runs/44109330056/artifacts/14340560757)
retains the frozen executable and JSON; archive digest
`da28d879c4babe8ec66bdef81ffbe50b5ddf956260c4a0a55138dd09738f7135`.

Final local rerun after the Apple gate correction: full static/shared CTest each
**134/134 PASS**, ELF **52** exports PASS, recorded Apple **49**-symbol replay PASS,
current shared consumers/package, full ordered external-provider parity **134/134**,
format 22.1.5, binary/source packages, installed CLI and policy/document gates PASS.
Final independent review found no important issue in the platform gate correction.
These remain internal maintenance checks, not an external audit or release authority.

Native Windows isolated console coverage **PASS** in both static and shared
jobs at head `289158aa9e49b2a8b3f5359de3b76587ef26b5f5`, PR merge `b029973`
(complete SHA in job checkout log). [Run 44107964573](https://github.com/anothel/AnoSecureKit-Community/actions/runs/44107964573)
passed all **11 validation jobs**; Release skipped. Windows shared job
[134125416775](https://github.com/anothel/AnoSecureKit-Community/actions/runs/44107964573/job/134125416775)
passed **133/133 CTests**, including `Cli.WindowsConsole` in 3.23 seconds;
static job [134125416936](https://github.com/anothel/AnoSecureKit-Community/actions/runs/44107964573/job/134125416936)
passed **133/133**, console regression in 4.19 seconds. This is actual Win32
console allocation and CLI execution, not redirected-input or mocked Win32 calls.
All eleven console cases completed, including both encoding cases and the VT LF
case. Windows shared exports and current installed shared consumers also passed.
Linux GCC/Clang Release/Debug/static/shared, ordered parity, sanitizers and
macOS-latest CTest/packages passed in the same run.

Final platform workflow at `f5e68f6e5c105414600aa02a3f10fcf7a9161487`:
[44109330056](https://github.com/anothel/AnoSecureKit-Community/actions/runs/44109330056)
completed with **all three native Linux, Windows and macOS-15 replacement jobs
PASS**. This includes current shared exports/packages and unchanged historical
binaries, with no recompilation after freezing. The later full main CI rerun is
[44109331342](https://github.com/anothel/AnoSecureKit-Community/actions/runs/44109331342);
its final status is recorded below. Earlier failed diagnostic runs remain evidence
of corrected test/gate portability defects, not failures silently waived.

At evidence closeout, final main CI run 44109331342 has **10/11 validation jobs
PASS** (including both Windows static/shared and all Linux jobs); its redundant
macOS-latest package job is still **QUEUED, not PASS**. The complete prior matrix
at 289158a passed, and the final revision's native macOS-15 shared replacement,
exception and installed-package lane passed independently. A queued job is not
claimed as execution. The final documentation-only commit records these immutable
outcomes and does not change the implementation tested at f5e68f6. Maintainers
must inspect the PR's current checks before any separately authorized merge.

Publication remains **NO-GO**. Phase 3 remains **DEFERRED**. Current alerts remain
unavailable rather than cleared; no security restrictions were bypassed. No merge,
release, tag, alert dismissal or publication was performed.
