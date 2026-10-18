"""Offline Makefile/Android tooling tests. No phone, Godot or GitHub needed."""
from __future__ import annotations

import contextlib
import hashlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import android_j8
import repo_sync


class J8ToolsTests(unittest.TestCase):
    def test_default_target_is_j8(self):
        self.assertEqual(android_j8.DEFAULT_DEVICE, "38c19745")
        self.assertEqual(android_j8.PACKAGE, "com.dantesouza.bastionzero")

    def test_profile_selection_by_current_branch(self):
        for key, branch in [
            ("m1r", "feature/m1-playable-game"),
            ("phase-a", "feature/m1-visual-phase-a"),
            ("phase-b", "feature/m1-visual-phase-b-guardian"),
            ("phase-c", "feature/m1-visual-phase-c-enemies"),
            ("phase-d", "feature/m1-visual-phase-d-weapons"),
            ("phase-e", "feature/m1-visual-phase-e-hud"),
            ("phase-f", "feature/m1-visual-phase-f-evolution")
        ]:
            with self.subTest(key=key), mock.patch.object(
                android_j8, "execute", return_value=mock.Mock(stdout=branch + "\n")
            ):
                self.assertEqual(android_j8.resolve_profile("auto").key, key)

    def test_unknown_branch_rejected_not_guessed(self):
        with mock.patch.object(
            android_j8, "execute", return_value=mock.Mock(stdout="dev\n")
        ):
            with self.assertRaisesRegex(RuntimeError, "Cannot infer"):
                android_j8.resolve_profile("auto")

    def test_phase_a_artifact_and_package_isolation(self):
        a = android_j8.resolve_profile("phase-a")
        b = android_j8.resolve_profile("m1r")
        self.assertNotEqual(a.package, b.package)
        self.assertNotEqual(a.apk_name, b.apk_name)
        self.assertNotEqual(a.artifact, b.artifact)
        self.assertIn("phase-a", str(android_j8.resolve_apk("auto", a)))
        self.assertIn("m1r", str(android_j8.resolve_apk("auto", b)))
        self.assertNotEqual(android_j8.resolve_apk("auto", a), android_j8.resolve_apk("auto", b))

    def test_phase_b_is_isolated_and_export_matches(self):
        b = android_j8.resolve_profile("phase-b")
        a = android_j8.resolve_profile("phase-a")
        self.assertNotEqual(b.package, a.package)
        self.assertNotEqual(b.apk_name, a.apk_name)
        self.assertNotEqual(b.artifact, a.artifact)
        self.assertIn("phase-b", str(android_j8.resolve_apk("auto", b)))
        self.assertTrue(b.package.endswith(".phaseb"))
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/phase-a/bastion-zero-phase-a-j8-debug.apk", b)

    def test_phase_c_isolated_and_j8_export_metadata(self):
        c = android_j8.resolve_profile("phase-c")
        b = android_j8.resolve_profile("phase-b")
        self.assertEqual(c.branch, "feature/m1-visual-phase-c-enemies")
        self.assertEqual(c.artifact, "Bastion-Zero-Phase-C-J8-ARMv7")
        self.assertEqual(c.package, "com.dantesouza.bastionzero.phasec")
        self.assertNotEqual(c.package, b.package)
        self.assertNotEqual(c.apk_name, b.apk_name)
        self.assertIn("dist", str(android_j8.resolve_apk("auto", c)))
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/phase-b/bastion-zero-phase-b-j8-debug.apk", c)

    def test_phase_d_isolated_showcase_apk_profile(self):
        d = android_j8.resolve_profile("phase-d")
        c = android_j8.resolve_profile("phase-c")
        self.assertEqual(d.branch, "feature/m1-visual-phase-d-weapons")
        self.assertEqual(d.artifact, "Bastion-Zero-Phase-D-J8-ARMv7")
        self.assertEqual(d.package, "com.dantesouza.bastionzero.phased")
        self.assertNotEqual(d.package, c.package)
        self.assertNotEqual(d.apk_name, c.apk_name)
        self.assertIn("phase-d", str(android_j8.resolve_apk("auto", d)))
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/phase-c/bastion-zero-phase-c-j8-debug.apk", d)

    def test_phase_e_isolated_apk_profile(self):
        e = android_j8.resolve_profile("phase-e")
        d = android_j8.resolve_profile("phase-d")
        self.assertEqual(e.branch, "feature/m1-visual-phase-e-hud")
        self.assertEqual(e.artifact, "Bastion-Zero-Phase-E-J8-ARMv7")
        self.assertEqual(e.package, "com.dantesouza.bastionzero.phasee")
        self.assertNotEqual(e.package, d.package)
        self.assertNotEqual(e.apk_name, d.apk_name)
        self.assertIn("phase-e", str(android_j8.resolve_apk("auto", e)))
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/phase-d/bastion-zero-phase-d-j8-debug.apk", e)

    def test_phase_f_isolated_stress_apk_profile(self):
        f = android_j8.resolve_profile("phase-f")
        e = android_j8.resolve_profile("phase-e")
        self.assertEqual(f.branch, "feature/m1-visual-phase-f-evolution")
        self.assertEqual(f.artifact, "Bastion-Zero-Phase-F-J8-ARMv7")
        self.assertEqual(f.package, "com.dantesouza.bastionzero.phasef")
        self.assertNotEqual(f.package, e.package)
        self.assertNotEqual(f.apk_name, e.apk_name)
        self.assertIn("phase-f", str(android_j8.resolve_apk("auto", f)))
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/phase-e/bastion-zero-phase-e-j8-debug.apk", f)

    def test_reject_cross_profile_apk_basename(self):
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/bastion-zero-j8-debug.apk", android_j8.PROFILES["phase-a"])

    def test_reinstall_does_not_uninstall_without_apk(self):
        with tempfile.TemporaryDirectory() as tmp:
            with mock.patch.object(android_j8, "uninstall") as remove, mock.patch.object(android_j8, "adb") as adb:
                with self.assertRaises(RuntimeError):
                    android_j8.reinstall("38c19745", Path(tmp) / "missing.apk", launch=True)
                remove.assert_not_called()
                adb.assert_not_called()

    def test_reinstall_uninstalls_only_phase_a(self):
        phase = android_j8.PROFILES["phase-a"]
        with mock.patch.object(android_j8, "apk_ready"), \
             mock.patch.object(android_j8, "installed", return_value=True) as check, \
             mock.patch.object(android_j8, "uninstall") as remove, \
             mock.patch.object(android_j8, "adb") as adb, \
             mock.patch.object(android_j8, "run") as launch, \
             contextlib.redirect_stdout(io.StringIO()):
            android_j8.reinstall("38c19745", Path(phase.apk_name), launch=True, package=phase.package)
        remove.assert_called_once_with("38c19745", phase.package)
        launch.assert_called_once_with("38c19745", phase.package)
        self.assertEqual(check.call_args_list[0].args, ("38c19745", phase.package))
        self.assertIn(phase.apk_name, str(adb.call_args_list[0]))

    def test_reinstall_absent_package_skips_uninstall(self):
        with mock.patch.object(android_j8, "apk_ready"), \
             mock.patch.object(android_j8, "installed", return_value=False), \
             mock.patch.object(android_j8, "uninstall") as remove, \
             mock.patch.object(android_j8, "adb"), \
             contextlib.redirect_stdout(io.StringIO()):
            android_j8.reinstall("38c19745", Path("bastion-zero-phase-a-j8-debug.apk"), launch=False,
                                 package=android_j8.PROFILES["phase-a"].package)
        remove.assert_not_called()

    def test_sha256_mismatch_prevents_install(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            apk = folder / "bastion-zero-phase-a-j8-debug.apk"
            apk.write_bytes(b"fake-apk")
            (folder / "SHA256SUMS.txt").write_text(
                "0" * 64 + "  dist/bastion-zero-phase-a-j8-debug.apk\n", encoding="utf-8"
            )
            with mock.patch.object(android_j8, "adb") as adb:
                with self.assertRaisesRegex(RuntimeError, "checksum mismatch"):
                    android_j8.install("38c19745", apk, android_j8.PROFILES["phase-a"].package)
                adb.assert_not_called()

    def test_good_sha256_preflights_apk(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            apk = folder / "bastion-zero-phase-a-j8-debug.apk"
            apk.write_bytes(b"sample-content")
            digest = hashlib.sha256(b"sample-content").hexdigest()
            (folder / "SHA256SUMS.txt").write_text(
                digest + "  dist/bastion-zero-phase-a-j8-debug.apk\n", encoding="utf-8"
            )
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(android_j8.apk_ready(apk, require_checksum=True), apk)

    def test_download_selects_latest_phase_a_run_and_reuses_cached_artifact(self):
        phase = android_j8.PROFILES["phase-a"]
        received = []

        def fake_exec(command, **kwargs):
            received.append(command)
            if command[:3] == ["gh", "run", "list"]:
                self.assertEqual(command[command.index("--branch") + 1], phase.branch)
                return mock.Mock(stdout=json.dumps([{"databaseId": 39149399652}]))
            if command[:3] == ["gh", "run", "view"]:
                return mock.Mock(stdout=json.dumps({
                    "headBranch": phase.branch, "conclusion": "success",
                    "workflowName": "Android J8 debug APK"
                }))
            if command[:3] == ["gh", "run", "download"]:
                self.assertEqual(command[command.index("--name") + 1], phase.artifact)
                folder = Path(command[command.index("--dir") + 1])
                (folder / phase.apk_name).write_bytes(b"test-phase-a-apk")
                (folder / "SHA256SUMS.txt").write_text(
                    hashlib.sha256(b"test-phase-a-apk").hexdigest() +
                    "  dist/" + phase.apk_name + "\n", encoding="utf-8"
                )
                return mock.Mock(stdout="")
            raise AssertionError(f"Unexpected command {command}")

        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp) / "phase-a" / phase.apk_name
            with mock.patch.object(android_j8.shutil, "which", return_value="gh"), \
                 mock.patch.object(android_j8, "execute", side_effect=fake_exec), \
                 contextlib.redirect_stdout(io.StringIO()):
                android_j8.download(dest, "latest", phase, "dante-souza/bastion_zero")
                android_j8.download(dest, "latest", phase, "dante-souza/bastion_zero")
            self.assertTrue(dest.is_file())
            self.assertEqual((dest.parent / ".run-id").read_text().strip(), "39149399652")
            self.assertEqual(sum(cmd[:3] == ["gh", "run", "download"] for cmd in received), 1)

    def test_download_rejects_other_branch_even_with_explicit_run_id(self):
        phase = android_j8.PROFILES["phase-a"]
        def fake_exec(cmd, **kwargs):
            return mock.Mock(stdout=json.dumps({
                "headBranch": "feature/m1-playable-game",
                "conclusion": "success", "workflowName": "Android J8 debug APK"
            }))
        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp) / "phase-a" / phase.apk_name
            with mock.patch.object(android_j8.shutil, "which", return_value="gh"), \
                 mock.patch.object(android_j8, "execute", side_effect=fake_exec):
                with self.assertRaisesRegex(RuntimeError, "mismatched artifact"):
                    android_j8.download(dest, "39143921890", phase, "dante-souza/bastion_zero")
            self.assertFalse(dest.exists())

    def test_installed_version_parsing(self):
        result = mock.Mock(stdout="  versionCode=8 minSdk=21 targetSdk=34\n  versionName=0.3.0-phase-a-debug\n")
        with mock.patch.object(android_j8, "adb", return_value=result), \
             contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertTrue(android_j8.installed("38c19745", android_j8.PROFILES["phase-a"].package))
        self.assertIn("versionCode=8 versionName=0.3.0-phase-a-debug", output.getvalue())

    def test_repo_sync_includes_visual_branch(self):
        self.assertIn("feature/m1-visual-phase-a", repo_sync.BRANCHES)
        self.assertIn("feature/m1-visual-phase-b-guardian", repo_sync.BRANCHES)
        self.assertIn("feature/m1-visual-phase-c-enemies", repo_sync.BRANCHES)
        self.assertIn("feature/m1-visual-phase-d-weapons", repo_sync.BRANCHES)
        self.assertIn("feature/m1-visual-phase-e-hud", repo_sync.BRANCHES)
        self.assertIn("feature/m1-visual-phase-f-evolution", repo_sync.BRANCHES)


if __name__ == "__main__":
    unittest.main()
