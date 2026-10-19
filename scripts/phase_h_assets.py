#!/usr/bin/env python3
"""Import approved Phase H imagery safely from a user-downloaded ZIP.

This is deliberately an explicit local operation: ChatGPT-generated images are
delivered as an artifact, not as remotely fetched runtime dependencies.
All resource paths, SHA-256 checksums and output locations are allow-listed.
"""
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import sys
import tempfile
from zipfile import ZipFile, BadZipFile

ROOT = Path(__file__).resolve().parent.parent
FOLDER = Path("assets/branding")
EXPECTED = {
    "premium_guardian_foreground_432.png": "fc26d01b8fe66c8b4055f1ad4564ab9d0398b02f641dba3da959703bce6f49a3",
    "premium_splash_720.png": "2465594a7623ec93234c1808ec001f42b5b77aa64a3e3c90698eb9ace9f902c1",
    "premium_guardian_background_432.png": "094501f452da14adae2b17a69cb931febaab3f829cb008b4db2a45df6dcbf025",
    "premium_hangar_hero.webp": "9eeab7b0e75bdbd1f834262944c0c8ec5585f13751dff3987f3d6ce33923f397",
    "premium_hangar_background.webp": "87a92ecce24c9dad5a97cc82a2409f038ea117fb21f6979dfbe83b73b5e5e0cb",
    "premium_guardian_launcher_192.png": "42840171276685c26cd6ceacd813ec21a098cacfd2f7b4113eeedf770f64a1d9",
}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def verify(root: Path = ROOT) -> bool:
    for name, sha in EXPECTED.items():
        path = root / FOLDER / name
        if not path.is_file() or digest(path.read_bytes()) != sha:
            return False
    return True


def _swap_one(text: str, old: str, new: str, description: str) -> str:
    if new in text:
        return text
    if old not in text:
        raise RuntimeError(f"Missing known {description} configuration; refusing unknown edit")
    return text.replace(old, new, 1)


def enable_premium_config(root: Path) -> None:
    project = root / "project.godot"
    original = project.read_text(encoding="utf-8")
    updated = _swap_one(
        original,
        'boot_splash/image="res://assets/branding/last_horizon_boot.png"',
        'boot_splash/image="res://assets/branding/premium_splash_720.png"',
        "Godot boot image"
    )
    if updated != original:
        project.write_text(updated, encoding="utf-8")

    preset_path = root / "export_presets.cfg"
    original = preset_path.read_text(encoding="utf-8")
    marker = "[preset.8.options]"
    if marker not in original:
        raise RuntimeError("Phase H Android preset missing: update to the Phase H branch first")
    pre, _, tail = original.partition(marker)
    if not tail:
        raise RuntimeError("Phase H Android options missing")
    for old, new, name in [
        ('launcher_icons/main_192x192="res://assets/branding/guardian_launcher_192.png"',
         'launcher_icons/main_192x192="res://assets/branding/premium_guardian_launcher_192.png"', "launcher"),
        ('launcher_icons/adaptive_foreground_432x432="res://assets/branding/guardian_adaptive_foreground_432.png"',
         'launcher_icons/adaptive_foreground_432x432="res://assets/branding/premium_guardian_foreground_432.png"', "adaptive foreground"),
        ('launcher_icons/adaptive_background_432x432="res://assets/branding/guardian_adaptive_background_432.png"',
         'launcher_icons/adaptive_background_432x432="res://assets/branding/premium_guardian_background_432.png"', "adaptive background"),
    ]:
        tail = _swap_one(tail, old, new, name)
    updated = pre + marker + tail
    if updated != original:
        preset_path.write_text(updated, encoding="utf-8")


def install_bundle(bundle: Path, root: Path = ROOT) -> None:
    if not bundle.is_file():
        raise RuntimeError(f"Art bundle not found: {bundle}")
    try:
        with ZipFile(bundle) as z:
            extracted = {}
            for name, sha in EXPECTED.items():
                member = (FOLDER / name).as_posix()
                if member not in z.namelist():
                    raise RuntimeError(f"Approved asset missing from bundle: {member}")
                raw = z.read(member)
                if digest(raw) != sha:
                    raise RuntimeError(f"SHA-256 mismatch: {member} (bundle changed)")
                extracted[name] = raw
    except BadZipFile as exc:
        raise RuntimeError(f"Not a valid approved art ZIP: {bundle}") from exc

    target = root / FOLDER
    target.mkdir(parents=True, exist_ok=True)
    # All six checksums must pass before any file is changed.
    for name, raw in extracted.items():
        output = target / name
        fd, temp = tempfile.mkstemp(prefix=".phase-h-", dir=target)
        try:
            with os.fdopen(fd, "wb") as f:
                f.write(raw)
            os.replace(temp, output)
        finally:
            if os.path.exists(temp):
                os.unlink(temp)
    if not verify(root):
        raise RuntimeError("Imported assets failed their post-write integrity check")
    enable_premium_config(root)
    print(f"Phase H assets verified and installed: {len(EXPECTED)} files")
    print("Android/Godot premium boot, hero and launcher icons configured.")
    print("Commit and push the six asset files plus project.godot and export_presets.cfg")
    print("before running make phase-h, so GitHub CI exports the actual premium art.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["install", "verify"])
    parser.add_argument("--bundle", default=None)
    parser.add_argument("--require", action="store_true",
                        help="Nonzero exit if premium images are absent/altered")
    args = parser.parse_args()
    try:
        if args.action == "install":
            if not args.bundle:
                raise RuntimeError('Pass ART_BUNDLE to make phase-h-art')
            install_bundle(Path(args.bundle).expanduser().resolve())
            return 0
        ok = verify()
        if ok:
            print("PASS: all six Phase H approved artwork files match SHA-256")
        elif args.require:
            raise RuntimeError("Phase H approved images absent: import art before Android export")
        else:
            print("NOTICE: Phase H premium bundle not installed; GitHub source uses Phase G fallback artwork")
        return 0
    except (OSError, RuntimeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
