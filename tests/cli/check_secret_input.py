# SPDX-License-Identifier: MPL-2.0
"""Bounded subprocess tests; real POSIX terminals, never the CI runner's tty."""
import os
import pathlib
import subprocess
import sys
import tempfile

cli = os.path.abspath(sys.argv[1])


def run(args, ok=False, **kw):
    p = subprocess.run([cli] + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       timeout=15, **kw)
    assert p.returncode == (0 if ok else 1), (args, p.returncode, p.stderr)
    assert not p.stdout
    assert b'secret-sentinel' not in p.stderr
    return p


with tempfile.TemporaryDirectory() as tmp:
    root = pathlib.Path(tmp)
    plain = root / 'plain'
    plain.write_bytes(b'payload\x00\xff')
    password = root / 'password'
    password.write_bytes(b' secret-sentinel\x00\xff\r\n')
    packet = root / 'packet'
    seal = ['seal-file-password', '--in', str(plain), '--out', str(packet)]
    verify = ['verify-file-password', '--in', str(packet)]
    run(seal + ['--password-file', str(password)], ok=True)
    run(verify + ['--password-file', str(password)], ok=True)
    for sources in [[], ['--password-prompt'], ['--password-fd', '-1'],
                    ['--password-fd', '2147483648'], ['--password-fd', 'x'], ['--secret-sentinel', 'value'],
                    ['--password-prompt', '--password-file', str(password)],
                    ['--password-file', str(password), '--password-prompt'],
                    ['--password-prompt', '--password-prompt'],
                    ['--password-file', str(password), '--password-fd', '0']]:
        run(verify + sources, input=b'secret-sentinel\n')
    empty = root / 'empty'
    empty.write_bytes(b'')
    run(verify + ['--password-file', str(empty)])
    if os.name == 'nt':
        p = run(verify + ['--password-fd', '0'], input=b'')
        assert p.stderr == b'password descriptors are unsupported on this platform' + os.linesep.encode(), p.stderr
    if os.name == 'posix':
        run(verify + ['--password-fd', '0'], input=password.read_bytes(), ok=True)
        run(verify + ['--password-fd', '0'], input=b'')
        run(verify + ['--password-fd', '99'])
        run(['verify-file-password', '--in', '-', '--password-fd', '0'], input=b'')
        with password.open('rb') as f:
            run(verify + ['--password-fd', str(f.fileno())], pass_fds=(f.fileno(),), ok=True)
        fd_packet = root / 'fd-packet'
        run(['seal-file-password', '--in', str(plain), '--out', str(fd_packet),
             '--password-fd', '0'], input=password.read_bytes(), ok=True)
        opened = root / 'opened'
        run(['open-file-password', '--in', str(fd_packet), '--out', str(opened),
             '--password-fd', '0'], input=password.read_bytes(), ok=True)
        assert opened.read_bytes() == plain.read_bytes()
        reader, writer = os.pipe()
        try:
            os.write(writer, password.read_bytes())
            os.close(writer)
            writer = -1
            run(['verify-file-password', '--in', '-', '--password-fd', str(reader)],
                input=packet.read_bytes(), pass_fds=(reader,), ok=True)
        finally:
            os.close(reader)
            if writer >= 0:
                os.close(writer)
        # An open writer would make a premature descriptor read hang.
        reader, writer = os.pipe()
        try:
            p = run(verify + ['--password-fd', str(reader), '--password-file', str(password)],
                    pass_fds=(reader,), input=b'')
            assert p.stderr == b'conflicting password sources\n'
        finally:
            os.close(reader)
            os.close(writer)
        import pty
        import select
        import termios
        import time

        def prompt(data, ok, expected=b'secret-sentinel'):
            master, slave = pty.openpty()
            before = termios.tcgetattr(slave)
            out = root / ('prompt-' + str(time.monotonic_ns()))
            args = ['seal-file-password', '--in', str(plain), '--out', str(out), '--password-prompt']
            p = subprocess.Popen([cli] + args, stdin=slave, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
            try:
                deadline = time.monotonic() + 5
                while termios.tcgetattr(slave)[3] & termios.ECHO:
                    assert p.poll() is None, 'prompt exited before disabling echo'
                    assert time.monotonic() < deadline, 'echo-disable timeout'
                    time.sleep(.01)
                os.write(master, data)
                stdout, stderr = p.communicate(timeout=15)
                assert p.returncode == (0 if ok else 1), stderr
                assert not stdout and b'secret-sentinel' not in stderr
                assert termios.tcgetattr(slave) == before, 'terminal mode not restored'
                assert not select.select([master], [], [], .05)[0], 'terminal echoed input'
                assert out.exists() == ok
                if ok:
                    password.write_bytes(expected)
                    run(['verify-file-password', '--in', str(out), '--password-file', str(password)], ok=True)
            finally:
                if p.poll() is None:
                    p.kill()
                    p.wait()
                os.close(master)
                os.close(slave)

        prompt(b'a\x11b\n', True, b'a\x11b')
        prompt(b'a\x13b\r', True, b'a\x13b')
        prompt(b'x' * 4096 + b'\n', True, b'x' * 4096)
        prompt(b'secret-sentinel\n', True)
        prompt(b'secret-sentineX\x7fl\n', True)
        for data in [b'\n', b'\x03', b'\x04', b'\x1a', b'x' * 4097 + b'\n']:
            prompt(data, False)
print('secret input checks passed')
