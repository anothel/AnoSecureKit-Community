# SPDX-License-Identifier: MPL-2.0
"""Real Win32 console input, never the runner's console. No password output.

A detached worker allocates a new console. Unsupported console allocation is a
failure, not a simulated pass; native CI is expected to provide this facility.
"""
import os
import pathlib
import subprocess
import sys
import tempfile
import time

if os.name != 'nt':
    raise SystemExit('requires native Windows')
cli = str(pathlib.Path(sys.argv[1]).resolve())
if '--worker' not in sys.argv:
    worker = subprocess.Popen([sys.executable, __file__, cli, '--worker'],
                              creationflags=subprocess.DETACHED_PROCESS,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        _, diagnostics = worker.communicate(timeout=150)
    except subprocess.TimeoutExpired:
        # Kill the CLI descendants while the worker PID still identifies the tree.
        subprocess.run(['taskkill', '/PID', str(worker.pid), '/T', '/F'],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10)
        worker.kill()
        worker.wait(timeout=5)
        raise SystemExit('isolated Windows console regression timed out')
    # Do not forward unexpected child diagnostics that might contain test input.
    if worker.returncode:
        # Worker emits only numeric progress markers; discard traceback contents.
        import re
        markers = re.findall(rb'console-stage [0-9]+ [a-z]+', diagnostics)
        detail = markers[-1].decode() if markers else 'worker setup'
        raise SystemExit('isolated Windows console regression failed: ' + detail)
    print('PASS: native isolated Win32 console input')
    raise SystemExit(0)

import ctypes as c
from ctypes import wintypes as w
import msvcrt

k = c.WinDLL('kernel32', use_last_error=True)


class Coord(c.Structure):
    _fields_ = [('X', w.SHORT), ('Y', w.SHORT)]


class Key(c.Structure):
    _fields_ = [('down', w.BOOL), ('repeat', w.WORD), ('vk', w.WORD),
                ('scan', w.WORD), ('char', w.WCHAR), ('state', w.DWORD)]


class Event(c.Union):
    _fields_ = [('key', Key), ('padding', c.c_byte * 16)]


class Record(c.Structure):
    _fields_ = [('type', w.WORD), ('event', Event)]


for name, args, result in [
    ('CreateFileW', [w.LPCWSTR, w.DWORD, w.DWORD, c.c_void_p, w.DWORD, w.DWORD, w.HANDLE], w.HANDLE),
    ('GetConsoleMode', [w.HANDLE, c.POINTER(w.DWORD)], w.BOOL),
    ('SetConsoleMode', [w.HANDLE, w.DWORD], w.BOOL),
    ('FlushConsoleInputBuffer', [w.HANDLE], w.BOOL),
    ('WriteConsoleInputW', [w.HANDLE, c.POINTER(Record), w.DWORD, c.POINTER(w.DWORD)], w.BOOL),
    ('ReadConsoleOutputCharacterW', [w.HANDLE, w.LPWSTR, w.DWORD, Coord, c.POINTER(w.DWORD)], w.BOOL),
    ('SetConsoleCP', [w.UINT], w.BOOL),
]:
    fn = getattr(k, name)
    fn.argtypes, fn.restype = args, result


def require(value):
    if not value:
        raise RuntimeError('Win32 console assertion failed')


require(k.AllocConsole())
h = k.CreateFileW('CONIN$', 0xC0000000, 3, None, 3, 0, None)
screen = k.CreateFileW('CONOUT$', 0xC0000000, 3, None, 3, 0, None)
require(h != w.HANDLE(-1).value and screen != w.HANDLE(-1).value)
fd = msvcrt.open_osfhandle(h, os.O_RDONLY)
console = os.fdopen(fd, 'rb', buffering=0)


def mode():
    value = w.DWORD()
    require(k.GetConsoleMode(h, c.byref(value)))
    return value.value


def inject(text):
    # Bounded batches avoid the console event buffer capacity on long input.
    for start in range(0, len(text), 64):
        chunk = text[start:start + 64]
        records = (Record * len(chunk))()
        for row, ch in zip(records, chunk):
            row.type = 1
            row.event.key = Key(1, 1, 0, 0, ch, 0)
        count = w.DWORD()
        require(k.WriteConsoleInputW(h, records, len(chunk), c.byref(count)))
        require(count.value == len(chunk))


def no_screen_secret(sentinel):
    # A fresh allocated screen; no cursor movement or scrolling is requested.
    data = c.create_unicode_buffer(80 * 300)
    count = w.DWORD()
    require(k.ReadConsoleOutputCharacterW(screen, data, len(data), Coord(0, 0), c.byref(count)))
    require(sentinel not in data.value)


with tempfile.TemporaryDirectory() as tmp:
    root = pathlib.Path(tmp)
    plain, password, packet = [root / x for x in ['plain', 'password', 'packet']]
    plain.write_bytes(b'console regression payload')
    sentinel = 'console-secret-sentinel'

    case_number = 0

    def case(text, expected, success=True, error=b'', cp=1252):
        global case_number
        case_number += 1

        def stage(name):
            print('console-stage', case_number, name, file=sys.stderr, flush=True)

        stage('setup')
        require(k.SetConsoleCP(cp))
        require(k.FlushConsoleInputBuffer(h))
        # Deliberately enable every mode the CLI must temporarily disable.
        require(k.SetConsoleMode(h, mode() | 7))
        saved = mode()
        password.write_bytes(expected)
        if packet.exists():
            packet.unlink()
        fixture = subprocess.run([cli, 'seal-file-password', '--in', str(plain),
                                  '--out', str(packet), '--password-file', str(password)],
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20)
        require(fixture.returncode == 0)
        child = subprocess.Popen([cli, 'verify-file-password', '--in', str(packet),
                                  '--password-prompt'], stdin=console,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            deadline = time.monotonic() + 5
            while mode() == saved and child.poll() is None and time.monotonic() < deadline:
                time.sleep(0.01)
            require(child.poll() is None and mode() == (saved & ~7))
            # Read the prompt as a handshake; modes alone precede prompt output.
            require(child.stderr.read(10) == b'Password: ')
            stage('inject')
            inject(text)
            stage('wait')
            stdout, stderr = child.communicate(timeout=20)
            stage('result')
            require(child.returncode == (0 if success else 1))
            require(not stdout and error in stderr)
            require(sentinel.encode() not in stderr)
            require(mode() == saved)
            stage('screen')
            no_screen_secret(sentinel)
            stage('done')
        finally:
            if child.poll() is None:
                child.kill()
                child.wait(timeout=5)
            require(k.SetConsoleMode(h, saved))

    case(sentinel + '\r', sentinel.encode())
    case(sentinel + 'x\b\r', sentinel.encode())
    case(sentinel + '\n', sentinel.encode())
    for cancel in ['\x03', '\x04', '\x1a']:
        case(sentinel + cancel, sentinel.encode(), False, b'password input cancelled')
    case('\r', b'nonempty', False, b'password must not be empty')
    boundary = sentinel + 'a' * (4096 - len(sentinel))
    case(boundary + '\r', boundary.encode())
    case(boundary + 'a', b'nonempty', False, b'password input too long')
    # ReadConsoleA converts Unicode key events using the console input code page.
    # These tests pin two explicit single-byte encodings, not portable UTF-8.
    case(sentinel + '\u00e9\r', sentinel.encode() + b'\xe9', cp=1252)
    case(sentinel + '\u00e9\r', sentinel.encode() + b'\x82', cp=437)
console.close()
require(k.FreeConsole())
