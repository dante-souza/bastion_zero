"""Offline tests for development scripts. No connected Android phone required."""
from __future__ import annotations

import contextlib
import io
from pathlib import Path
import tempfile
import unittest
from unittest import mock
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import android_j8


class J8ToolsTests(unittest.TestCase):
    def test_default_target_is_j8(self):
        self.assertEqual(android_j8.DEFAULT_DEVICE, "38c19745")
        self.assertEqual(android_j8.PACKAGE, "com.dantesouza.bastionzero")

    def test_reinstall_does_not_uninstall_without_apk(self):
        with tempfile.TemporaryDirectory() as tmp:
            with mock.patch.object(android_j8, "uninstall") as remove, mock.patch.object(android_j8, "adb") as adb:
                with self.assertRaises(RuntimeError):
                    android_j8.reinstall("38c19745", Path(tmp) / "missing.apk", launch=True)
                remove.assert_not_called()
                adb.assert_not_called()

    def test_sha256_mismatch_prevents_install(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            (folder / "bastion-zero-j8-debug.apk").write_bytes(b"fake-apk")
            (folder / "SHA256SUMS.txt").write_text("0" * 64 + "  dist/bastion-zero-j8-debug.apk\n", encoding="utf-8")
            with mock.patch.object(android_j8, "adb") as adb:
                with self.assertRaisesRegex(RuntimeError, "checksum mismatch"):
                    android_j8.install("38c19745", folder / "bastion-zero-j8-debug.apk")
                adb.assert_not_called()

    def test_good_sha256_preflights_apk(self):
        import hashlib
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            apk = folder / "bastion-zero-j8-debug.apk"
            apk.write_bytes(b"sample-content")
            digest = hashlib.sha256(b"sample-content").hexdigest()
            (folder / "SHA256SUMS.txt").write_text(digest + "  dist/bastion-zero-j8-debug.apk\n", encoding="utf-8")
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(android_j8.apk_ready(apk), apk)

    def test_latest_run_selection_uses_successful_j8_branch(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            apk = folder / "bastion-zero-j8-debug.apk"
            def fake_exec(command, **kwargs):
                if "run" in command and "list" in command:
                    return mock.Mock(stdout="39139851446\n")
                # Simulate gh extracting the expected artifact with its checksum.
                apk.write_bytes(b"apk")
                import hashlib
                (folder / "SHA256SUMS.txt").write_text(
                    hashlib.sha256(b"apk").hexdigest() + "  dist/bastion-zero-j8-debug.apk\n",
                    encoding="utf-8",
                )
                return mock.Mock(stdout="")
            with mock.patch.object(android_j8, "shutil") as util, \
                 mock.patch.object(android_j8, "execute", side_effect=fake_exec) as exec_mock, \
                 contextlib.redirect_stdout(io.StringIO()):
                util.which.return_value = "gh"
                android_j8.download(apk, "latest", "Bastion-Zero-M1R-J8-ARMv7", "dante-souza/bastion_zero")
            command = exec_mock.call_args_list[-1].args[0]
            self.assertIn("39139851446", command)

    def test_installed_version_parsing(self):
        result = mock.Mock(stdout="  versionCode=4 minSdk=21 targetSdk=34\n  versionName=0.2.1-combat-debug\n")
        with mock.patch.object(android_j8, "adb", return_value=result):
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                self.assertTrue(android_j8.installed("38c19745"))
            self.assertIn("versionCode=4 versionName=0.2.1-combat-debug", output.getvalue())


if __name__ == "__main__":
    unittest.main()
