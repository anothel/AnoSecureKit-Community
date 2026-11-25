# SPDX-License-Identifier: MPL-2.0
"""Whole-file stdout release checks with synthetic SKF1 and SKP1 inputs."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

CLI = str(Path(sys.argv.pop(1)).resolve())
LINUX = sys.platform.startswith("linux")
PAYLOADS = (b"", bytes(range(256)), bytes(range(256)) * 4097)


class VerifiedStdout(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        directory = tempfile.TemporaryDirectory(prefix="ask-verified-stdout-")
        cls.directory = directory
        cls.root = Path(directory.name)
        cls.stage = cls.root / "stage"
        cls.stage.mkdir()
        cls.target = cls.stage / "sentinel"
        cls.target.write_bytes(b"untouched")
        cls.link = cls.stage / "link"
        if LINUX:
            cls.link.symlink_to(cls.target)
        password = cls.root / "password"
        password.write_bytes(b"synthetic password")
        wrong_password = cls.root / "wrong-password"
        wrong_password.write_bytes(b"wrong synthetic password")
        cls.credentials = {
            "": ("--key-hex", "01" * 32),
            "-password": ("--password-file", password),
        }
        cls.wrong_credentials = {
            "": ("--key-hex", "02" * 32),
            "-password": ("--password-file", wrong_password),
        }
        cls.packets = {}
        for index, payload in enumerate(PAYLOADS):
            plain = cls.root / ("plain-%d" % index)
            plain.write_bytes(payload)
            for suffix, cred in cls.credentials.items():
                packet = cls.root / ("packet-%d%s" % (index, suffix))
                result = cls.cli(["seal-file" + suffix, "--in", plain, "--out", packet,
                                  *cred, "--aad-text", "test aad"])
                if (result.returncode, result.stdout, result.stderr) != (0, b"", b""):
                    raise AssertionError(result.stderr)
                cls.packets[suffix, index] = packet

    @classmethod
    def tearDownClass(cls):
        cls.directory.cleanup()

    @classmethod
    def cli(cls, args, data=None, stage=None, stdin=None, stdout=subprocess.PIPE):
        return subprocess.run([CLI, *map(str, args)], input=data, stdin=stdin, stdout=stdout,
                              stderr=subprocess.PIPE, timeout=20,
                              env=dict(os.environ, TMPDIR=str(stage or cls.stage)))

    def open_args(self, suffix, source, out="-", credentials=None, aad="test aad"):
        return ["open-file" + suffix, "--in", source, "--out", out,
                *(self.credentials[suffix] if credentials is None else credentials),
                "--aad-text", aad]

    def assert_clean_failure(self, result, diagnostic=None):
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(result.stdout, b"")
        self.assertTrue(result.stderr)
        if diagnostic is not None:
            self.assertEqual(result.stderr, diagnostic)

    def tearDown(self):
        expected = [self.target, self.link] if LINUX else [self.target]
        self.assertCountEqual(self.stage.iterdir(), expected)
        self.assertEqual(self.target.read_bytes(), b"untouched")
        if LINUX:
            self.assertTrue(self.link.is_symlink())

    @unittest.skipUnless(LINUX, "Linux anonymous staging")
    def test_exact_file_and_stdin_round_trips(self):
        for (suffix, index), packet in self.packets.items():
            for source in (packet, "-"):
                with self.subTest(suffix=suffix, size=len(PAYLOADS[index]), source=source):
                    args = self.open_args(suffix, source)
                    args.insert(1, "--verified-stdout")
                    result = self.cli(args, packet.read_bytes() if source == "-" else None)
                    self.assertEqual((result.returncode, result.stderr), (0, b""))
                    self.assertEqual(result.stdout, PAYLOADS[index])

    @unittest.skipUnless(LINUX, "Linux anonymous staging")
    def test_authentication_and_structure_fail_with_empty_stdout(self):
        for suffix in self.credentials:
            packet = self.packets[suffix, 2]
            valid = packet.read_bytes()
            invalid_inputs = {
                "terminal-tag": valid[:-1] + bytes([valid[-1] ^ 1]),
                "truncated": valid[:-1],
                "trailing": valid + b"extra",
            }
            for failure, contents in invalid_inputs.items():
                damaged = self.root / ("damaged-" + failure + suffix)
                damaged.write_bytes(contents)
                for source in (damaged, "-"):
                    with self.subTest(suffix=suffix, failure=failure, source=source):
                        self.assert_clean_failure(self.cli(
                            [*self.open_args(suffix, source), "--verified-stdout"],
                            contents if source == "-" else None),
                            b"File authentication failed\n" if failure == "terminal-tag" else None)
            for credentials, aad in ((self.wrong_credentials[suffix], "test aad"),
                                     (self.credentials[suffix], "wrong aad")):
                with self.subTest(suffix=suffix, aad=aad):
                    self.assert_clean_failure(self.cli(
                        [*self.open_args(suffix, packet, credentials=credentials, aad=aad),
                         "--verified-stdout"]), b"File authentication failed\n")

    @unittest.skipUnless(LINUX, "Linux anonymous staging")
    def test_stdin_read_error_is_not_end_of_input(self):
        for suffix in self.credentials:
            with self.subTest(suffix=suffix):
                packet = self.packets[suffix, 1].read_bytes()
                read_end, write_end = os.pipe()
                with os.fdopen(read_end, "rb") as input_pipe, os.fdopen(write_end, "wb") as writer:
                    os.set_blocking(input_pipe.fileno(), False)
                    writer.write(packet)
                    writer.flush()
                    # All bytes are available, but the open writer makes the trailing
                    # read fail with EAGAIN instead of returning end of input.
                    self.assert_clean_failure(self.cli(
                        [*self.open_args(suffix, "-"), "--verified-stdout"], stdin=input_pipe),
                        b"failed to read input file\n")

    def test_invalid_options(self):
        for suffix in self.credentials:
            packet = self.packets[suffix, 1]
            out = self.root / ("invalid-out" + suffix)
            stdout_args = self.open_args(suffix, packet)
            for args in (
                [*stdout_args, "--verified-stdout", "--verified-stdout"],
                [*stdout_args, "--verified-stdout", "true"],
                [*self.open_args(suffix, packet, out), "--verified-stdout"],
                [*stdout_args, "--verified-stdout", "--out", "-"],
                ["seal-file" + suffix, *stdout_args[1:], "--verified-stdout"],
                ["verify-file" + suffix, "--in", packet, *self.credentials[suffix],
                 "--verified-stdout"],
                ["open-file" + suffix, "--in", packet, *self.credentials[suffix],
                 "--verified-stdout"],
            ):
                with self.subTest(command=args[0], options=args[1:]):
                    self.assert_clean_failure(self.cli(args))
                    self.assertFalse(out.exists())

    def test_default_stdout_path_and_verify_compatibility(self):
        for suffix, cred in self.credentials.items():
            packet = self.packets[suffix, 2]
            out = self.root / ("restored" + suffix)
            result = self.cli(self.open_args(suffix, packet))
            self.assertEqual((result.returncode, result.stdout, result.stderr), (0, PAYLOADS[2], b""))
            result = self.cli(self.open_args(suffix, packet, out))
            self.assertEqual((result.returncode, result.stdout, result.stderr), (0, b"", b""))
            self.assertEqual(out.read_bytes(), PAYLOADS[2])
            result = self.cli(["verify-file" + suffix, "--in", packet, *cred,
                               "--aad-text", "test aad"])
            self.assertEqual((result.returncode, result.stdout, result.stderr), (0, b"", b""))

    @unittest.skipUnless(LINUX, "Linux anonymous staging")
    def test_staging_creation_and_stdout_errors(self):
        stage_alias = self.root / "stage-alias"
        stage_alias.symlink_to(self.stage, target_is_directory=True)
        for suffix in self.credentials:
            args = [*self.open_args(suffix, self.packets[suffix, 2]), "--verified-stdout"]
            for stage in (self.root / "missing", self.link, str(stage_alias) + "/"):
                with self.subTest(suffix=suffix, stage=stage):
                    self.assert_clean_failure(self.cli(args, stage=stage),
                                              b"failed to create verified stdout staging file\n")
            with open("/dev/full", "wb") as full:
                result = self.cli(args, stdout=full)
            self.assertEqual((result.returncode, result.stderr), (1, b"failed to write stdout\n"))
            read_end, write_end = os.pipe()
            os.close(read_end)
            with os.fdopen(write_end, "wb") as closed_pipe:
                result = self.cli(args, stdout=closed_pipe)
            self.assertEqual((result.returncode, result.stderr), (1, b"failed to write stdout\n"))

    @unittest.skipIf(LINUX, "Linux anonymous staging")
    def test_unsupported_platform_fails_closed(self):
        for suffix in self.credentials:
            packet = self.packets[suffix, 2]
            for source in (packet, "-"):
                self.assert_clean_failure(self.cli(
                    [*self.open_args(suffix, source), "--verified-stdout"],
                    packet.read_bytes() if source == "-" else None),
                    b"verified stdout staging is unsupported on this platform" + os.linesep.encode())


if __name__ == "__main__":
    unittest.main()
