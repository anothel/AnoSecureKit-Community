# SPDX-License-Identifier: MPL-2.0
"""Deterministic Linux syscall/stdio failures in isolated test processes."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

DRIVER, HOOKS = map(lambda p: str(Path(p).resolve()), sys.argv[1:3])
del sys.argv[1:3]


class FileIoFaults(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="ask-io-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.input = self.root / "input"
        self.input.write_bytes(b"private payload")
        self.password = self.root / "password"
        self.password.write_bytes(b"p")
        self.output = self.root / "output"
        self.marker = self.root / "marker"
        self.key = "00" * 32
        self.sealed = {}
        for suffix in ("", "-password"):
            target = self.root / ("sealed" + suffix)
            result = self.run_process(["seal" + suffix, self.input, target, "unused"])
            self.assertEqual(result.returncode, 0, result.stderr)
            self.sealed[suffix] = target

    def run_process(self, args, fault=None):
        env = dict(os.environ)
        if fault:
            env.update(LD_PRELOAD=HOOKS, ASK_IO_ROOT=str(self.root),
                       ASK_IO_MARKER=str(self.marker), ASK_IO_FAULT=fault,
                       ASK_IO_STDIN="1" if "-" in args else "")
        data = None
        if "-" in args:
            source = self.sealed["-password" if "--password-file" in args else ""] if str(args[1]).startswith("open") else self.input
            data = source.read_bytes()
        return subprocess.run([DRIVER, *map(str, args)], env=env, input=data,
                              capture_output=True, timeout=30)

    def routes(self):
        for suffix in ("", "-password"):
            for op in ("seal", "open"):
                source = self.input if op == "seal" else self.sealed[suffix]
                yield "library", [op + suffix, source, self.output, "unused"]
                credentials = (["--password-file", self.password] if suffix else
                               ["--key-hex", self.key])
                yield "library-cli", ["cli", op + "-file" + suffix, "--in", source,
                                      "--out", self.output, *credentials]
                yield "cli", ["cli", op + "-file" + suffix, "--in", "-",
                              "--out", self.output, *credentials]
        yield "cli", ["cli", "keygen", "--out", self.output]

    def clean(self):
        if self.output.exists():
            self.output.unlink()
        if self.marker.exists():
            self.marker.unlink()
        for path in self.root.glob("output.anosecurekit.*.tmp"):
            path.unlink()

    def test_failure_matrix(self):
        for kind, args in self.routes():
            faults = ["open", "fsync", "link", "unlink", "unlink-persistent", "race"]
            if kind != "cli":
                faults += ["fdopen", "input-open", "read", "flush", "fclose",
                           "fwrite", "fwrite-eintr", "read-eintr", "directory-open",
                           "directory-sync", "directory-close"]
            else:
                faults += ["write", "close", "short-write", "write-eintr"]
                if "keygen" not in args:
                    faults += ["read"]
            for fault in faults:
                with self.subTest(kind=kind, command=args[0:2], fault=fault):
                    self.clean()
                    result = self.run_process(args, fault)
                    self.assertTrue(self.marker.exists(), f"hook not reached: {result.stderr!r}")
                    success = fault in ("short-write", "write-eintr", "read-eintr")
                    expected = 0 if success else (5 if kind == "library" and fault == "race" else 1)
                    self.assertEqual(result.returncode, expected, result.stderr)
                    self.assertEqual(result.stdout, b"")
                    if not success:
                        self.assertIn(result.stderr, {
                            b"File open failed\n", b"File read failed\n",
                            b"File write failed\n", b"File rename failed\n",
                            b"Directory open failed\n", b"Directory sync failed\n",
                            b"Temporary file removal failed\n",
                            b"Output file already exists\n",
                            b"failed to write output file\n",
                            b"failed to open output file\n",
                            b"failed to open input file\n",
                            b"failed to read input file\n",
                        })
                        self.assertNotIn(str(self.root).encode(), result.stderr)
                        self.assertNotIn(b"private payload", result.stderr)
                        self.assertNotIn(b"descriptor leak", result.stderr)
                    committed = success or fault in ("unlink", "unlink-persistent", "directory-open", "directory-sync", "directory-close", "race")
                    self.assertEqual(self.output.exists(), committed)
                    if fault == "race":
                        self.assertEqual(self.output.read_bytes(), b"sentinel")
                    temps = list(self.root.glob("output.anosecurekit.*.tmp"))
                    self.assertEqual(len(temps), 1 if fault == "unlink-persistent" else 0)
                    if committed and fault != "race":
                        if "keygen" in args:
                            self.assertEqual(len(bytes.fromhex(self.output.read_text().strip())), 32)
                        elif str(args[0]).startswith("open") or (kind != "library" and str(args[1]).startswith("open")):
                            self.assertEqual(self.output.read_bytes(), self.input.read_bytes())
                        else:
                            verified = self.root / "verified"
                            if verified.exists():
                                verified.unlink()
                            suffix = "-password" if "password" in str(args) else ""
                            check = self.run_process(["open" + suffix, self.output, verified, "unused"])
                            self.assertEqual(check.returncode, 0, check.stderr)
                            self.assertEqual(verified.read_bytes(), self.input.read_bytes())

    def test_existing_destination_preserved(self):
        for kind, args in self.routes():
            with self.subTest(kind=kind, command=args[0:2]):
                self.clean()
                self.output.write_bytes(b"sentinel")
                result = self.run_process(args, "open")
                self.assertEqual(result.returncode, 5 if kind == "library" else 1, result.stderr)
                self.assertFalse(self.marker.exists())
                self.assertEqual(self.output.read_bytes(), b"sentinel")
                self.assertEqual(list(self.root.glob("output.anosecurekit.*.tmp")), [])


if __name__ == "__main__":
    unittest.main()
