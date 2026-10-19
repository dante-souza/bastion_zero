"""Offline Makefile/Android tooling tests. No phone, Godot or GitHub needed."""
from __future__ import annotations

import contextlib
import hashlib
import io
import json
from pathlib import Path
from zipfile import ZipFile
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import android_j8
import repo_sync
import phase_h_assets


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
            ("phase-f", "feature/m1-visual-phase-f-evolution"),
            ("phase-g", "feature/m1-visual-phase-g-identity-hangar"),
            ("phase-h", "feature/m1-visual-phase-h-premium"),
            ("phase-i1", "feature/m1-visual-phase-i1-combat-hud"),
            ("phase-i2", "feature/m1-visual-phase-i2-evolution"),
            ("phase-i3", "feature/m1-visual-phase-i3-title-menu"),
            ("phase-i4", "feature/m1-visual-phase-i4-threat-language"),
            ("phase-i5", "feature/m1-visual-phase-i5-color-language")
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

    def test_phase_g_isolated_last_horizon_apk(self):
        g = android_j8.resolve_profile("phase-g")
        f = android_j8.resolve_profile("phase-f")
        self.assertEqual(g.branch, "feature/m1-visual-phase-g-identity-hangar")
        self.assertEqual(g.artifact, "Bastion-Zero-Phase-G-J8-ARMv7")
        self.assertEqual(g.package, "com.dantesouza.bastionzero.phaseg")
        self.assertNotEqual(g.package, f.package)
        self.assertNotEqual(g.apk_name, f.apk_name)
        self.assertIn("phase-g", str(android_j8.resolve_apk("auto", g)))
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/phase-f/bastion-zero-phase-f-j8-debug.apk", g)

    def test_phase_h_bundle_is_verified_and_idempotent(self):
        data = b"pretend-synthetic-image"
        sha = hashlib.sha256(data).hexdigest()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "project.godot").write_text(
                'boot_splash/image="res://assets/branding/last_horizon_boot.png"\n',
                encoding="utf-8"
            )
            (root / "export_presets.cfg").write_text(
                '[preset.7.options]\n'
                'launcher_icons/main_192x192="other-preserved.png"\n'
                '[preset.8.options]\n'
                'launcher_icons/main_192x192="res://assets/branding/guardian_launcher_192.png"\n'
                'launcher_icons/adaptive_foreground_432x432="res://assets/branding/guardian_adaptive_foreground_432.png"\n'
                'launcher_icons/adaptive_background_432x432="res://assets/branding/guardian_adaptive_background_432.png"\n',
                encoding="utf-8"
            )
            bundle = root / "approved.zip"
            with ZipFile(bundle, "w") as z:
                z.writestr("assets/branding/sample.webp", data)
            with mock.patch.dict(phase_h_assets.EXPECTED, {"sample.webp": sha}, clear=True):
                self.assertFalse(phase_h_assets.verify(root))
                with contextlib.redirect_stdout(io.StringIO()):
                    phase_h_assets.install_bundle(bundle, root)
                    phase_h_assets.install_bundle(bundle, root)
                self.assertTrue(phase_h_assets.verify(root))
                self.assertEqual((root / "assets/branding/sample.webp").read_bytes(), data)
                self.assertIn("premium_splash_720.png", (root / "project.godot").read_text())
                preset = (root / "export_presets.cfg").read_text()
                self.assertIn("premium_guardian_launcher_192.png", preset)
                self.assertIn("other-preserved.png", preset)
                (root / "assets/branding/sample.webp").write_bytes(b"tampered")
                self.assertFalse(phase_h_assets.verify(root))

    def test_phase_h_bundle_rejects_tampering_before_install(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            bundle = root / "bad.zip"
            with ZipFile(bundle, "w") as z:
                z.writestr("assets/branding/sample.webp", b"tampered")
            with mock.patch.dict(
                phase_h_assets.EXPECTED, {"sample.webp": hashlib.sha256(b"good").hexdigest()},
                clear=True
            ):
                with self.assertRaisesRegex(RuntimeError, "SHA-256 mismatch"):
                    phase_h_assets.install_bundle(bundle, root)
                self.assertFalse((root / "assets/branding/sample.webp").exists())

    def test_phase_h_independent_premium_profile(self):
        h = android_j8.resolve_profile("phase-h")
        g = android_j8.resolve_profile("phase-g")
        self.assertEqual(h.branch, "feature/m1-visual-phase-h-premium")
        self.assertEqual(h.artifact, "Bastion-Zero-Phase-H-J8-ARMv7")
        self.assertEqual(h.package, "com.dantesouza.bastionzero.phaseh")
        self.assertNotEqual(h.package, g.package)
        self.assertNotEqual(h.apk_name, g.apk_name)
        self.assertIn("phase-h", str(android_j8.resolve_apk("auto", h)))
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/phase-g/bastion-zero-phase-g-j8-debug.apk", h)

    def test_phase_i1_updates_existing_phase_h_app_without_another_icon(self):
        h = android_j8.resolve_profile("phase-h")
        i = android_j8.resolve_profile("phase-i1")
        self.assertEqual(i.branch, "feature/m1-visual-phase-i1-combat-hud")
        self.assertEqual(i.artifact, "Bastion-Zero-Phase-I1-J8-ARMv7")
        self.assertEqual(i.package, h.package)
        self.assertNotEqual(i.apk_name, h.apk_name)
        self.assertIn("phase-i1", str(android_j8.resolve_apk("auto", i)))
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/phase-h/bastion-zero-phase-h-j8-debug.apk", i)

    def test_phase_i2_three_card_android_build_reuses_premium_app(self):
        phase_h = android_j8.resolve_profile("phase-h")
        i1 = android_j8.resolve_profile("phase-i1")
        i2 = android_j8.resolve_profile("phase-i2")
        self.assertEqual(i2.branch, "feature/m1-visual-phase-i2-evolution")
        self.assertEqual(i2.artifact, "Bastion-Zero-Phase-I2-J8-ARMv7")
        self.assertEqual(i2.package, phase_h.package)
        self.assertEqual(i2.package, i1.package)
        self.assertNotEqual(i2.apk_name, i1.apk_name)
        self.assertIn("phase-i2", str(android_j8.resolve_apk("auto", i2)))
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/phase-i1/bastion-zero-phase-i1-j8-debug.apk", i2)

    def test_phase_i3_title_reuses_premium_android_app(self):
        h = android_j8.resolve_profile("phase-h")
        i2 = android_j8.resolve_profile("phase-i2")
        i3 = android_j8.resolve_profile("phase-i3")
        self.assertEqual(i3.branch, "feature/m1-visual-phase-i3-title-menu")
        self.assertEqual(i3.artifact, "Bastion-Zero-Phase-I3-J8-ARMv7")
        self.assertEqual(i3.package, h.package)
        self.assertEqual(i3.package, i2.package)
        self.assertNotEqual(i3.apk_name, i2.apk_name)
        self.assertIn("phase-i3", str(android_j8.resolve_apk("auto", i3)))
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/phase-i2/bastion-zero-phase-i2-j8-debug.apk", i3)

    def test_phase_i4_threat_guide_reuses_premium_app(self):
        h = android_j8.resolve_profile("phase-h")
        i3 = android_j8.resolve_profile("phase-i3")
        i4 = android_j8.resolve_profile("phase-i4")
        self.assertEqual(i4.branch, "feature/m1-visual-phase-i4-threat-language")
        self.assertEqual(i4.artifact, "Bastion-Zero-Phase-I4-J8-ARMv7")
        self.assertEqual(i4.package, h.package)
        self.assertEqual(i4.package, i3.package)
        self.assertNotEqual(i4.apk_name, i3.apk_name)
        self.assertIn("phase-i4", str(android_j8.resolve_apk("auto", i4)))
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/phase-i3/bastion-zero-phase-i3-j8-debug.apk", i4)

    def test_phase_i5_color_language_reuses_premium_app(self):
        h = android_j8.resolve_profile("phase-h")
        i4 = android_j8.resolve_profile("phase-i4")
        i5 = android_j8.resolve_profile("phase-i5")
        self.assertEqual(i5.branch, "feature/m1-visual-phase-i5-color-language")
        self.assertEqual(i5.artifact, "Bastion-Zero-Phase-I5-J8-ARMv7")
        self.assertEqual(i5.package, h.package)
        self.assertEqual(i5.package, i4.package)
        self.assertNotEqual(i5.apk_name, i4.apk_name)
        self.assertIn("phase-i5", str(android_j8.resolve_apk("auto", i5)))
        with self.assertRaisesRegex(RuntimeError, "cross-profile"):
            android_j8.resolve_apk("dist/phase-i4/bastion-zero-phase-i4-j8-debug.apk", i5)

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
        self.assertIn("feature/m1-visual-phase-g-identity-hangar", repo_sync.BRANCHES)
        self.assertIn("feature/m1-visual-phase-h-premium", repo_sync.BRANCHES)
        self.assertIn("feature/m1-visual-phase-i1-combat-hud", repo_sync.BRANCHES)
        self.assertIn("feature/m1-visual-phase-i2-evolution", repo_sync.BRANCHES)
        self.assertIn("feature/m1-visual-phase-i3-title-menu", repo_sync.BRANCHES)
        self.assertIn("feature/m1-visual-phase-i4-threat-language", repo_sync.BRANCHES)
        self.assertIn("feature/m1-visual-phase-i5-color-language", repo_sync.BRANCHES)


if __name__ == "__main__":
    unittest.main()
