# SPDX-License-Identifier: MPL-2.0
"""Observable POSIX CLI output contracts; uses only the Python standard library."""
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import time
import unittest

CLI = str(Path(sys.argv.pop(1)).resolve())


@unittest.skipUnless(os.name == "posix", "POSIX permissions and commit race")
class OutputSecurity(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="anosecurekit-cli-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.key = "00" * 32
        self.wrong_key = "11" * 32
        self.password = self.root / "password"
        self.password.write_bytes(b"test password\n")
        self.plain = self.root / "plain"
        self.plain.write_bytes(b"x" * (1048576 + 31))
        self.packet = self.root / "packet"
        self.wrapped = self.root / "wrapped"
        self.skf = self.root / "skf"
        self.skp = self.root / "skp"
        for args in (
            ["encrypt", "--text", "secret", "--key-hex", self.key, "--out", self.packet],
            ["wrap-key", "--key-hex", self.key, "--wrapping-key-hex", self.key,
             "--out", self.wrapped],
            ["seal-file", "--in", self.plain, "--key-hex", self.key, "--out", self.skf],
            ["seal-file-password", "--in", self.plain, "--password-file", self.password,
             "--out", self.skp],
        ):
            self.success(args)

    def run_cli(self, args, data=None):
        # Set umask in the parent only: this test process has no worker threads.
        old_mask = os.umask(self.mask if hasattr(self, "mask") else 0o022)
        try:
            return subprocess.run([CLI, *map(str, args)], input=data,
                                  capture_output=True, timeout=20)
        finally:
            os.umask(old_mask)

    def success(self, args, data=None):
        result = self.run_cli(args, data)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((result.stdout, result.stderr), (b"", b""))

    def clean_output(self, output):
        self.assertFalse(os.path.lexists(output))
        self.assertEqual(list(self.root.glob(output.name + ".anosecurekit.*.tmp")), [])

    def commands(self):
        # Every CLI command that owns a path output, plus both stdin file profiles.
        yield ["keygen"]
        yield ["wrap-key", "--key-hex", self.key, "--wrapping-key-hex", self.key]
        yield ["unwrap-key", "--packet-file", self.wrapped, "--wrapping-key-hex", self.key]
        yield ["encrypt", "--in", self.plain, "--key-hex", self.key]
        yield ["decrypt", "--packet-file", self.packet, "--key-hex", self.key]
        for password, sealed in ((False, self.skf), (True, self.skp)):
            credential = (["--password-file", self.password] if password else
                          ["--key-hex", self.key])
            suffix = "-password" if password else ""
            for operation, source in (("seal-file", self.plain), ("open-file", sealed)):
                yield [operation + suffix, "--in", source, *credential]
                yield [operation + suffix, "--in", "-", *credential]

    def input_for(self, args):
        if "--in" in args and args[args.index("--in") + 1] == "-":
            source = (self.skp if args[0].endswith("-password") else self.skf)
            return source.read_bytes() if args[0].startswith("open") else self.plain.read_bytes()
        return None

    def test_private_outputs_and_no_overwrite(self):
        for self.mask in (0o000, 0o022):
            for index, args in enumerate(self.commands()):
                with self.subTest(umask=self.mask, command=args[0], index=index):
                    output = self.root / f"output-{self.mask}-{index}"
                    legacy = Path(str(output) + ".anosecurekit.tmp")
                    legacy.write_bytes(b"legacy sentinel")
                    self.success([*args, "--out", output], self.input_for(args))
                    self.assertEqual(stat.S_IMODE(output.stat().st_mode), 0o600)
                    original = output.read_bytes()
                    result = self.run_cli([*args, "--out", output], self.input_for(args))
                    self.assertEqual(result.returncode, 1, result.stderr)
                    self.assertEqual(result.stdout, b"")
                    self.assertEqual(output.read_bytes(), original)
                    self.assertEqual(legacy.read_bytes(), b"legacy sentinel")
                    self.assertEqual(list(self.root.glob(output.name + ".anosecurekit.*.tmp")),
                                     [])

    def test_existing_symlinks_and_directories_preserved(self):
        for index, args in enumerate(self.commands()):
            for kind in ("symlink", "dangling", "directory"):
                with self.subTest(command=args[0], index=index, kind=kind):
                    output = self.root / f"collision-{index}-{kind}"
                    target = self.root / f"target-{index}-{kind}"
                    if kind == "directory":
                        output.mkdir()
                    else:
                        if kind == "symlink":
                            target.write_bytes(b"target sentinel")
                        output.symlink_to(target)
                    result = self.run_cli([*args, "--out", output], self.input_for(args))
                    self.assertEqual(result.returncode, 1, result.stderr)
                    self.assertEqual(result.stdout, b"")
                    if kind == "directory":
                        self.assertTrue(output.is_dir())
                    else:
                        self.assertTrue(output.is_symlink())
                        if kind == "symlink":
                            self.assertEqual(target.read_bytes(), b"target sentinel")
                        else:
                            self.assertFalse(target.exists())
                    self.assertEqual(list(self.root.glob(output.name + ".anosecurekit.*.tmp")), [])

    def test_authentication_failure_cleanup(self):
        for password, sealed in ((False, self.skf), (True, self.skp)):
            damaged = self.root / ("damaged-" + sealed.name)
            contents = bytearray(sealed.read_bytes())
            contents[-1] ^= 1  # Fail final tag after a full authenticated chunk.
            damaged.write_bytes(contents)
            suffix = "-password" if password else ""
            credential = (["--password-file", self.password] if password else
                          ["--key-hex", self.key])
            for source in (damaged, "-"):
                with self.subTest(password=password, source=source):
                    output = self.root / "failed-output"
                    result = self.run_cli(
                        ["open-file" + suffix, "--in", source, "--out", output, *credential],
                        damaged.read_bytes() if source == "-" else None)
                    self.assertEqual(result.returncode, 1)
                    self.assertEqual(result.stdout, b"")
                    self.assertEqual(result.stderr, b"File authentication failed\n")
                    self.clean_output(output)
            # stdout cannot roll back earlier verified chunks.
            result = self.run_cli(
                ["open-file" + suffix, "--in", damaged, "--out", "-", *credential])
            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stderr, b"File authentication failed\n")
            self.assertEqual(result.stdout, self.plain.read_bytes()[:1048576])

        for args in (
            ["decrypt", "--packet-file", self.packet, "--key-hex", self.wrong_key],
            ["unwrap-key", "--packet-file", self.wrapped, "--wrapping-key-hex", self.wrong_key],
        ):
            output = self.root / "failed-packet"
            result = self.run_cli([*args, "--out", output])
            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout, b"")
            self.assertEqual(result.stderr, b"AEAD authentication failed\n")
            self.clean_output(output)

    def test_destination_created_before_commit_is_preserved(self):
        for password in (False, True):
            with self.subTest(password=password):
                output = self.root / ("race-password" if password else "race-key")
                suffix = "-password" if password else ""
                credential = (["--password-file", str(self.password)] if password else
                              ["--key-hex", self.key])
                process = subprocess.Popen(
                    [CLI, "seal-file" + suffix, "--in", "-", "--out", str(output), *credential],
                    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                try:
                    # Keep stdin open so the child cannot finalize or commit.
                    deadline = time.monotonic() + 10
                    temporary = []
                    while time.monotonic() < deadline and process.poll() is None:
                        temporary = list(self.root.glob(output.name + ".anosecurekit.*.tmp"))
                        if temporary:
                            break
                        time.sleep(0.01)
                    self.assertEqual(len(temporary), 1)
                    self.assertEqual(stat.S_IMODE(temporary[0].stat().st_mode), 0o600)
                    output.write_bytes(b"racing writer sentinel")
                    stdout, stderr = process.communicate(b"secret", timeout=20)
                    self.assertEqual(process.returncode, 1)
                    self.assertEqual(stdout, b"")
                    self.assertEqual(stderr, b"Output file already exists\n")
                    self.assertEqual(output.read_bytes(), b"racing writer sentinel")
                    self.assertEqual(list(self.root.glob(output.name + ".anosecurekit.*.tmp")), [])
                finally:
                    if process.poll() is None:
                        process.kill()
                    process.communicate()


if __name__ == "__main__":
    unittest.main()
