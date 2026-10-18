#!/usr/bin/env python3
"""Bastion Zero: branch-aware, profile-safe Android J8 Makefile backend."""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


@dataclass(frozen=True)
class BuildProfile:
    key: str
    branch: str
    artifact: str
    apk_name: str
    package: str


PROFILES = {
    "m1r": BuildProfile(
        "m1r", "feature/m1-playable-game", "Bastion-Zero-M1R-J8-ARMv7",
        "bastion-zero-j8-debug.apk", "com.dantesouza.bastionzero"
    ),
    "phase-a": BuildProfile(
        "phase-a", "feature/m1-visual-phase-a", "Bastion-Zero-Phase-A-J8-ARMv7",
        "bastion-zero-phase-a-j8-debug.apk", "com.dantesouza.bastionzero.phasea"
    ),
    "phase-b": BuildProfile(
        "phase-b", "feature/m1-visual-phase-b-guardian", "Bastion-Zero-Phase-B-J8-ARMv7",
        "bastion-zero-phase-b-j8-debug.apk", "com.dantesouza.bastionzero.phaseb"
    ),
    "phase-c": BuildProfile(
        "phase-c", "feature/m1-visual-phase-c-enemies", "Bastion-Zero-Phase-C-J8-ARMv7",
        "bastion-zero-phase-c-j8-debug.apk", "com.dantesouza.bastionzero.phasec"
    ),
    "phase-d": BuildProfile(
        "phase-d", "feature/m1-visual-phase-d-weapons", "Bastion-Zero-Phase-D-J8-ARMv7",
        "bastion-zero-phase-d-j8-debug.apk", "com.dantesouza.bastionzero.phased"
    ),
    "phase-e": BuildProfile(
        "phase-e", "feature/m1-visual-phase-e-hud", "Bastion-Zero-Phase-E-J8-ARMv7",
        "bastion-zero-phase-e-j8-debug.apk", "com.dantesouza.bastionzero.phasee"
    ),
    "phase-f": BuildProfile(
        "phase-f", "feature/m1-visual-phase-f-evolution", "Bastion-Zero-Phase-F-J8-ARMv7",
        "bastion-zero-phase-f-j8-debug.apk", "com.dantesouza.bastionzero.phasef"
    ),
    "phase-g": BuildProfile(
        "phase-g", "feature/m1-visual-phase-g-identity-hangar", "Bastion-Zero-Phase-G-J8-ARMv7",
        "bastion-zero-phase-g-j8-debug.apk", "com.dantesouza.bastionzero.phaseg"
    ),
    "phase-h": BuildProfile(
        "phase-h", "feature/m1-visual-phase-h-premium", "Bastion-Zero-Phase-H-J8-ARMv7",
        "bastion-zero-phase-h-j8-debug.apk", "com.dantesouza.bastionzero.phaseh"
    ),
}
PACKAGE = PROFILES["m1r"].package  # backward-compatible testing alias
DEFAULT_DEVICE = os.environ.get("BASTION_DEVICE", "38c19745")
ROOT = Path(__file__).resolve().parent.parent

COMMANDS = {
    "profile": "Show selected branch, artifact, package and APK path",
    "doctor": "Check selected J8, installed package and local APK",
    "installed": "Inspect installed version of selected package",
    "download": "Fetch latest successful build of selected profile (cached safely)",
    "install": "Install/update selected package without deleting saves",
    "uninstall": "Remove only selected package and its local save",
    "reinstall": "Verify selected APK then uninstall/install its package (ERASES SAVE)",
    "run": "Launch selected package",
    "reinstall-run": "Verify, reinstall and launch selected package (ERASES SAVE)",
    "logs": "Show recent Android/Godot logs",
    "screenshot": "Capture PNG of device into screenshots/ (ignored by Git)",
}


def execute(argv: list[str], *, check: bool = True, capture: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        argv, check=check, text=True, capture_output=capture,
        encoding="utf-8", errors="replace"
    )


def adb(serial: str, *args: str, check: bool = True, capture: bool = False) -> subprocess.CompletedProcess[str]:
    return execute(["adb", "-s", serial, *args], check=check, capture=capture)


def resolve_profile(name: str) -> BuildProfile:
    if name == "auto":
        branch = execute(["git", "-C", str(ROOT), "branch", "--show-current"], capture=True).stdout.strip()
        for profile in PROFILES.values():
            if branch == profile.branch:
                return profile
        raise RuntimeError(
            f"Cannot infer Android profile from Git branch {branch!r}. "
            "Use 'make phase-h', or explicitly set PROFILE=phase-h|phase-g|phase-f|phase-e|phase-d|phase-c|phase-b|phase-a|m1r."
        )
    if name not in PROFILES:
        raise RuntimeError(f"Unknown PROFILE={name!r}; supported: auto, {', '.join(PROFILES)}")
    return PROFILES[name]


def resolve_apk(filename: str, profile: BuildProfile) -> Path:
    if filename == "auto":
        return ROOT / "dist" / profile.key / profile.apk_name
    apk = Path(filename).expanduser()
    if not apk.is_absolute():
        apk = ROOT / apk
    if apk.name != profile.apk_name:
        raise RuntimeError(
            f"APK basename {apk.name!r} does not match {profile.key} "
            f"({profile.apk_name!r}); refusing a cross-profile install."
        )
    return apk


def device_ready(serial: str) -> None:
    if not shutil.which("adb"):
        raise RuntimeError("ADB not found in PATH. Install Android platform-tools or configure PATH.")
    result = execute(["adb", "devices", "-l"], capture=True)
    lines = result.stdout.splitlines()[1:]
    match = next((line for line in lines if line.split()[:1] == [serial]), "")
    if not match:
        raise RuntimeError(f"Device {serial} not found. Connect J8, authorize USB debugging and retry.")
    if len(match.split()) < 2 or match.split()[1] != "device":
        raise RuntimeError(f"Device {serial} is not authorized/online: {match}")
    model = adb(serial, "shell", "getprop", "ro.product.model", capture=True).stdout.strip()
    print(f"ADB target: {serial} ({model})", flush=True)
    if serial == "38c19745" and model not in {"SM-J810M", "SM_J810M"}:
        raise RuntimeError(f"Expected Samsung Galaxy J8 at default serial; got {model!r}.")


def apk_ready(apk: Path, *, require_checksum: bool = False) -> Path:
    if not apk.is_file() or apk.stat().st_size == 0:
        raise RuntimeError(f"APK missing or empty: {apk}. Run 'make apk' or 'make phase-a-apk'.")
    sha_file = apk.parent / "SHA256SUMS.txt"
    if not sha_file.is_file():
        if require_checksum:
            raise RuntimeError(f"Missing artifact checksum: {sha_file}")
        print("WARNING: APK has no SHA256SUMS.txt; integrity cannot be verified.", flush=True)
    else:
        matched = False
        for line in sha_file.read_text(encoding="utf-8").splitlines():
            fields = line.split()
            if len(fields) >= 2 and Path(fields[-1]).name == apk.name:
                expected = fields[0].lower()
                actual = hashlib.sha256(apk.read_bytes()).hexdigest()
                if expected != actual:
                    raise RuntimeError(f"APK checksum mismatch! Expected {expected}, got {actual}")
                matched = True
                print(f"APK SHA-256 verified: {actual}", flush=True)
                break
        if not matched:
            raise RuntimeError(f"{sha_file} does not list {apk.name}; refusing ambiguous APK.")
    print(f"APK selected: {apk} ({apk.stat().st_size:,} bytes)", flush=True)
    return apk


def installed(serial: str, package: str = PACKAGE) -> bool:
    result = adb(serial, "shell", "dumpsys", "package", package, capture=True, check=False)
    version = re.search(r"\bversionCode=(\d+)", result.stdout)
    name = re.search(r"\bversionName=(\S+)", result.stdout)
    if not version or not name:
        print(f"{package}: not installed (or no package details available).", flush=True)
        return False
    print(f"{package}: versionCode={version.group(1)} versionName={name.group(1)}", flush=True)
    return True


def install(serial: str, apk: Path, package: str = PACKAGE) -> None:
    apk_ready(apk)
    print(f"Installing {package} without erasing data...", flush=True)
    adb(serial, "install", "-r", str(apk))
    installed(serial, package)


def uninstall(serial: str, package: str = PACKAGE) -> None:
    print(f"Removing {package} (its local save will be erased)...", flush=True)
    adb(serial, "uninstall", package)


def reinstall(serial: str, apk: Path, *, launch: bool, package: str = PACKAGE) -> None:
    # Essential ordering: verify selected APK BEFORE uninstalling anything.
    apk_ready(apk)
    print(f"Reinstalling only {package}. Its saved progress will be erased.", flush=True)
    if installed(serial, package):
        uninstall(serial, package)
    else:
        print("Target package absent; no uninstall necessary.", flush=True)
    adb(serial, "install", str(apk))
    installed(serial, package)
    if launch:
        run(serial, package)


def run(serial: str, package: str = PACKAGE) -> None:
    print(f"Starting {package} on {serial}...", flush=True)
    adb(serial, "shell", "monkey", "-p", package, "-c", "android.intent.category.LAUNCHER", "1")


def _run_details(run_id: str, repo: str) -> dict:
    raw = execute([
        "gh", "run", "view", run_id, "--repo", repo,
        "--json", "headBranch,conclusion,workflowName"
    ], capture=True).stdout
    return json.loads(raw)


def download(apk: Path, run_id: str, profile: BuildProfile, repo: str) -> None:
    if not shutil.which("gh"):
        raise RuntimeError("GitHub CLI gh unavailable. Install gh and authenticate with 'gh auth login'.")
    if run_id == "latest":
        raw = execute([
            "gh", "run", "list", "--repo", repo, "--workflow", "android-j8.yml",
            "--branch", profile.branch, "--status", "success", "--limit", "1",
            "--json", "databaseId"
        ], capture=True).stdout
        found = json.loads(raw)
        if not found:
            raise RuntimeError(f"No successful Android J8 build found for {profile.branch}.")
        run_id = str(found[0]["databaseId"])
    if not re.fullmatch(r"\d+", run_id):
        raise RuntimeError("RUN_ID must be 'latest' or a numeric GitHub Actions run ID.")
    details = _run_details(run_id, repo)
    if details.get("headBranch") != profile.branch or details.get("conclusion") != "success" or details.get("workflowName") != "Android J8 debug APK":
        raise RuntimeError(f"Run {run_id} is not a successful {profile.branch} Android build; refusing mismatched artifact.")
    print(f"Selected {profile.key} Android CI run: {run_id}", flush=True)

    marker = apk.parent / ".run-id"
    if marker.exists() and marker.read_text(encoding="utf-8").strip() == run_id:
        try:
            apk_ready(apk, require_checksum=True)
            print("Already downloaded and verified this run; no overwrite needed.", flush=True)
            return
        except RuntimeError:
            print("Cached artifact invalid; downloading a clean copy.", flush=True)

    apk.parent.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=f".{profile.key}-", dir=apk.parent.parent) as tmp:
        folder = Path(tmp)
        execute([
            "gh", "run", "download", run_id, "--repo", repo,
            "--name", profile.artifact, "--dir", str(folder)
        ])
        staged_apk = folder / profile.apk_name
        apk_ready(staged_apk, require_checksum=True)
        apk.parent.mkdir(parents=True, exist_ok=True)
        os.replace(staged_apk, apk)
        os.replace(folder / "SHA256SUMS.txt", apk.parent / "SHA256SUMS.txt")
        marker.write_text(run_id + "\n", encoding="utf-8")
    apk_ready(apk, require_checksum=True)


def logs(serial: str) -> None:
    result = adb(serial, "logcat", "-d", "-t", "350", capture=True)
    matches = [s for s in result.stdout.splitlines() if re.search(
        r"BastionZero|Godot|com\.dantesouza\.bastionzero|FATAL EXCEPTION", s, re.I
    )]
    for line in matches[-100:]:
        print(line)
    if not matches:
        print("No related entries in last 350 log lines.")


def screenshot(serial: str, profile: BuildProfile) -> None:
    folder = ROOT / "screenshots"
    folder.mkdir(parents=True, exist_ok=True)
    name = f"{profile.key}-{datetime.now().strftime('%Y%m%d-%H%M%S')}.png"
    path = folder / name
    with path.open("wb") as target:
        subprocess.run(["adb", "-s", serial, "exec-out", "screencap", "-p"], check=True, stdout=target)
    if path.stat().st_size < 100:
        path.unlink(missing_ok=True)
        raise RuntimeError("Screenshot capture returned no PNG data.")
    print(f"Screenshot saved: {path}")


def help_text() -> None:
    print("Bastion Zero — Makefile-first Galaxy J8 workflow")
    print("  make phase-a              download latest Phase A, reinstall and launch on J8")
    print("  make phase-a-apk          download/cache Phase A APK only")
    print("  make phase-a-reinstall-run  reinstall existing Phase A APK and launch")
    print("  make phase-a-run          launch installed Phase A")
    print("  make phase-a-doctor       check J8, Phase A package and APK")
    print("  make phase-a-logs         Android diagnostics")
    print("  make phase-a-screenshot   save screenshot in screenshots/")
    print("  make phase-b              download, reinstall and launch Guardian Phase B.1")
    print("  make phase-b-apk          download/cache Phase B.1 APK")
    print("  make phase-b-reinstall-run  reinstall cached Phase B.1 APK and launch")
    print("  make phase-b-run          launch installed Phase B")
    print("  make phase-b-doctor       check J8, Phase B package and APK")
    print("  make phase-b-logs         Android diagnostics")
    print("  make phase-b-screenshot   save screenshot in screenshots/")
    print("  make phase-c              download, reinstall and launch Phase C enemies")
    print("  make phase-c-apk          download/cache Phase C APK")
    print("  make phase-c-reinstall-run  reinstall cached Phase C APK and launch")
    print("  make phase-c-run          launch installed Phase C build")
    print("  make phase-c-doctor       check J8, Phase C package and APK")
    print("  make phase-c-logs         Android diagnostics")
    print("  make phase-c-screenshot   save screenshot in screenshots/")
    print("  make phase-d              download, reinstall and launch Phase D effects + showcase")
    print("  make phase-d-apk          download/cache Phase D APK")
    print("  make phase-d-reinstall-run  reinstall cached Phase D APK and launch")
    print("  make phase-d-run          launch installed Phase D build")
    print("  make phase-d-doctor       check J8, Phase D package and APK")
    print("  make phase-d-logs         Android diagnostics")
    print("  make phase-d-screenshot   save screenshot in screenshots/")
    print("  make phase-e              download, reinstall and launch D.1 + E")
    print("  make phase-e-apk          download/cache Phase E APK")
    print("  make phase-e-reinstall-run  reinstall cached Phase E APK and launch")
    print("  make phase-e-run          launch installed Phase E build")
    print("  make phase-e-doctor       check J8, Phase E package and APK")
    print("  make phase-e-logs         Android diagnostics")
    print("  make phase-e-screenshot   save screenshot in screenshots/")
    print("  make phase-f              download, reinstall and launch dense Phase F showcase")
    print("  make phase-f-apk          download/cache Phase F APK")
    print("  make phase-f-reinstall-run  reinstall cached Phase F APK and launch")
    print("  make phase-f-run          launch installed Phase F build")
    print("  make phase-f-doctor       check J8, Phase F package and APK")
    print("  make phase-f-logs         Android diagnostics")
    print("  make phase-f-screenshot   save screenshot in screenshots/")
    print("  make phase-g              download, reinstall and launch Last Horizon Hangar")
    print("  make phase-g-apk          download/cache Phase G APK")
    print("  make phase-g-reinstall-run  reinstall cached Phase G APK and launch")
    print("  make phase-g-run          launch installed Phase G build")
    print("  make phase-g-doctor       check J8, Phase G package and APK")
    print("  make phase-g-logs         Android diagnostics")
    print("  make phase-g-screenshot   save screenshot in screenshots/")
    print("  make phase-h              download, reinstall and launch premium Phase H")
    print("  make phase-h-art          import approved cinematic art ZIP; specify ART_BUNDLE=")
    print("  make phase-h-art-check    verify all six premium image SHA-256 hashes")
    print("  make phase-h-apk          download/cache Phase H APK")
    print("  make phase-h-reinstall-run  reinstall cached Phase H APK and launch")
    print("  make phase-h-run          launch installed Phase H build")
    print("  make phase-h-doctor       check J8, Phase H package and APK")
    print("  make phase-h-logs         Android diagnostics")
    print("  make phase-h-screenshot   save screenshot in screenshots/")
    print("  make fresh                download/reinstall/run selected branch profile")
    for key, value in COMMANDS.items():
        print(f"  make {key:<20} {value}")
    print("  make sync                 Fast-forward local main/dev/M1R/Phase-A/Phase-B/Phase-C/Phase-D/Phase-E/Phase-F/Phase-G/Phase-H and restore branch")
    print("  make check-tools          Python developer tool tests")
    print("  make check                Python + headless Godot validations")
    print("  make git-status           Inspect current local Git branch")
    print("  Overrides: PROFILE=phase-h|phase-g|phase-f|phase-e|phase-d|phase-c|phase-b|phase-a|m1r|auto, DEVICE=serial, APK=path, RUN_ID=number")
    print("  Default DEVICE=38c19745 (Galaxy J8); saves in the selected package are disposable.")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", default=DEFAULT_DEVICE)
    parser.add_argument("--profile", default="auto")
    parser.add_argument("--apk", default="auto")
    parser.add_argument("command", choices=[*COMMANDS, "help"])
    parser.add_argument("--run-id", default="latest")
    parser.add_argument("--repo", default="dante-souza/bastion_zero")
    args = parser.parse_args(argv)
    try:
        if args.command == "help":
            help_text()
            return 0
        profile = resolve_profile(args.profile)
        apk = resolve_apk(args.apk, profile)
        if args.command == "profile":
            print(f"Profile: {profile.key}\nBranch: {profile.branch}\nArtifact: {profile.artifact}\nAPK: {apk}\nPackage: {profile.package}")
            return 0
        if args.command == "download":
            download(apk, args.run_id, profile, args.repo)
            return 0
        device_ready(args.device)
        if args.command == "doctor":
            print(f"Selected profile: {profile.key} ({profile.package})")
            installed(args.device, profile.package)
            if apk.is_file():
                apk_ready(apk)
            else:
                print(f"Local APK not found: {apk}. Run make apk or make phase-a-apk.")
        elif args.command == "installed":
            installed(args.device, profile.package)
        elif args.command == "install":
            install(args.device, apk, profile.package)
        elif args.command == "uninstall":
            if installed(args.device, profile.package):
                uninstall(args.device, profile.package)
            else:
                print("Nothing to uninstall.")
        elif args.command == "reinstall":
            reinstall(args.device, apk, launch=False, package=profile.package)
        elif args.command == "reinstall-run":
            reinstall(args.device, apk, launch=True, package=profile.package)
        elif args.command == "run":
            run(args.device, profile.package)
        elif args.command == "logs":
            logs(args.device)
        elif args.command == "screenshot":
            screenshot(args.device, profile)
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError, subprocess.CalledProcessError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
