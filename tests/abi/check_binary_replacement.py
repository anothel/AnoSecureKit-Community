# SPDX-License-Identifier: MPL-2.0
"""Build once against a pinned old install, then replace only its runtime library.

The consumer is never rebuilt after freezing. A missing-library negative control
proves that the installed runtime is required (rather than an incidental copy).
Run in a disposable directory; toolchain arguments follow -- on the command line.
"""
import argparse
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import tarfile

BASELINE = '0cb8bda7b6d96a11bd83228321707f83d62daa4c'
p = argparse.ArgumentParser()
p.add_argument('source', type=pathlib.Path)
p.add_argument('work', type=pathlib.Path)
p.add_argument('cmake_args', nargs=argparse.REMAINDER)
a = p.parse_args()
# Loader failure must not open a modal Windows error dialog in the negative control.
if os.name == 'nt':
    import ctypes
    ctypes.windll.kernel32.SetErrorMode(0x8003)
source = a.source.resolve()
work = a.work.resolve()
work.mkdir(parents=True, exist_ok=False)
extra = a.cmake_args
if extra[:1] == ['--']:
    extra = extra[1:]


def run(args, **kwargs):
    return subprocess.run([str(x) for x in args], check=True, timeout=300, **kwargs)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


archive = work / 'baseline.tar'
with archive.open('wb') as out:
    run(['git', '-C', source, 'archive', BASELINE], stdout=out)
old = work / 'old-source'
old.mkdir()
# Trusted git archive of a fixed repository revision; no downloaded tar input.
with tarfile.open(archive) as tar:
    tar.extractall(old)
archive.unlink()
prefix = work / 'install'
for label, tree in [('old', old), ('new', source)]:
    build = work / (label + '-build')
    install = prefix if label == 'old' else work / 'new-install'
    run(['cmake', '-S', tree, '-B', build, '-DCMAKE_BUILD_TYPE=Release',
         '-DBUILD_SHARED_LIBS=ON', '-DANOSECUREKIT_BUILD_TESTS=OFF',
         '-DANOSECUREKIT_BUILD_CLI=OFF', '-DANOSECUREKIT_INSTALL_CLI=OFF'] + extra)
    run(['cmake', '--build', build, '--config', 'Release'])
    if label == 'new':
        run(['cmake', '--build', build, '--config', 'Release', '--target', 'shared-symbol-check', 'shared-package-check'])
    run(['cmake', '--install', build, '--config', 'Release', '--prefix', install])

consumer = work / 'consumer'
run(['cmake', '-S', old / 'tests/consumer', '-B', consumer,
     '-DCMAKE_BUILD_TYPE=Release', '-DCMAKE_PREFIX_PATH=' + str(prefix),
     '-DANOSECUREKIT_EXPECTED_VERSION=0.4.1', '-DANOSECUREKIT_EXPECTED_VERSION_MAJOR=0',
     '-DANOSECUREKIT_EXPECTED_VERSION_MINOR=4', '-DANOSECUREKIT_EXPECTED_VERSION_PATCH=1'] + extra)
run(['cmake', '--build', consumer, '--config', 'Release'])
exe = next(x for x in [consumer / 'Release/anosecurekit_consumer.exe',
                       consumer / 'anosecurekit_consumer.exe',
                       consumer / 'anosecurekit_consumer'] if x.is_file())
frozen = digest(exe)
name = 'anosecurekit.dll' if os.name == 'nt' else (
    'libanosecurekit.dylib' if __import__('sys').platform == 'darwin' else 'libanosecurekit.so')
lib = next(prefix.rglob(name)).resolve()
replacement = next((work / 'new-install').rglob(name)).resolve()
env = os.environ.copy()
env['PATH'] = str(prefix / 'bin') + os.pathsep + env['PATH']
env['LD_LIBRARY_PATH'] = str(lib.parent)
env['DYLD_LIBRARY_PATH'] = str(lib.parent)
# Use a private temp directory: the historical consumer uses fixed temp names.
scratch = work / 'scratch'
scratch.mkdir()
for key in ['TMP', 'TEMP', 'TMPDIR']:
    env[key] = str(scratch)
run([exe], env=env, cwd=scratch)
old_hash = digest(lib)
hidden = lib.with_name(lib.name + '.hidden')
lib.rename(hidden)
try:
    missing = subprocess.run([str(exe)], env=env, cwd=scratch, timeout=30,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert missing.returncode != 0, 'missing runtime negative control unexpectedly passed'
finally:
    hidden.rename(lib)
shutil.copyfile(replacement, lib)
assert digest(lib) == digest(replacement), 'replacement runtime mismatch'
assert old_hash != digest(lib), 'baseline and replacement runtimes are identical'
run([exe], env=env, cwd=scratch)
assert digest(exe) == frozen, 'frozen consumer changed'
evidence = dict(baseline=BASELINE, candidate=subprocess.check_output(
    ['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip(),
    platform=__import__('platform').platform(), consumer_sha256=frozen,
    baseline_library_sha256=old_hash, replacement_library_sha256=digest(lib),
    missing_library_control='failed as required', baseline_run='PASS', replacement_run='PASS')
(work / 'evidence.json').write_text(json.dumps(evidence, indent=2) + '\n')
print(json.dumps(evidence, indent=2))
