#!/usr/bin/env python3
"""Bastion Zero's safe J8 ADB workflow. Standard library only."""
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

PACKAGE = "com.dantesouza.bastionzero"
DEFAULT_DEVICE = os.environ.get("BASTION_DEVICE", "38c19745")
DEFAULT_APK = os.environ.get("BASTION_APK", "dist/bastion-zero-j8-debug.apk")
ROOT = Path(__file__).resolve().parent.parent

COMMANDS = {
    "doctor": "Check ADB connection, installed version and APK file",
    "installed": "Print the installed Android version without modifying anything",
    "download": "Download a specific GitHub Actions APK artifact (requires gh auth login)",
    "install": "Install/update APK without deleting existing app data",
    "uninstall": "REMOVE Bastion Zero AND ITS LOCAL SAVE from selected device",
    "reinstall": "Precheck APK, uninstall old version, install new APK (DELETES SAVE)",
    "run": "Launch the installed game on the selected device",
    "reinstall-run": "Precheck APK, uninstall, install, and launch (DELETES SAVE)",
    "logs": "Show relevant recent Android logs",
}


def execute(argv: list[str], *, check: bool = True, capture: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        argv, check=check, text=True, capture_output=capture,
        encoding="utf-8", errors="replace",
    )


def adb(serial: str, *args: str, check: bool = True, capture: bool = False) -> subprocess.CompletedProcess[str]:
    return execute(["adb", "-s", serial, *args], check=check, capture=capture)


def device_ready(serial: str) -> None:
    if not shutil.which("adb"):
        raise RuntimeError("ADB not found in PATH. Install Android platform-tools or configure PATH.")
    result = execute(["adb", "devices", "-l"], capture=True)
    lines = result.stdout.splitlines()[1:]
    match = next((line for line in lines if line.split()[:1] == [serial]), "")
    if not match:
        raise RuntimeError(f"Device {serial} not found. Connect the J8, authorize USB debugging and run 'adb devices -l'.")
    if len(match.split()) < 2 or match.split()[1] != "device":
        raise RuntimeError(f"Device {serial} is not authorized/online: {match}")
    model = adb(serial, "shell", "getprop", "ro.product.model", capture=True).stdout.strip()
    print(f"ADB target: {serial} ({model})")
    if serial == "38c19745" and model not in {"SM-J810M", "SM_J810M"}:
        raise RuntimeError(f"Expected Samsung Galaxy J8 for default serial; got {model!r}.")


def apk_ready(apk: Path) -> Path:
    if not apk.is_file() or apk.stat().st_size == 0:
        raise RuntimeError(
            f"APK missing or empty: {apk}\n"
            "Download the GitHub Actions artifact ZIP, extract the APK into dist/, "
            "or use 'make apk' (requires authenticated gh CLI)."
        )
    sha_file = apk.parent / "SHA256SUMS.txt"
    if sha_file.is_file():
        # GitHub Actions writes: <64 hex>  dist/bastion-zero-j8-debug.apk.
        matched = False
        for line in sha_file.read_text(encoding="utf-8").splitlines():
            fields = line.split()
            if len(fields) >= 2 and Path(fields[-1]).name == apk.name:
                expected = fields[0].lower()
                actual = hashlib.sha256(apk.read_bytes()).hexdigest()
                if actual != expected:
                    raise RuntimeError(f"APK checksum mismatch! Expected {expected}, got {actual}; refusing install.")
                print(f"APK SHA-256 verified: {actual}")
                matched = True
                break
        if not matched:
            raise RuntimeError(f"{sha_file} does not list {apk.name}; refusing ambiguous install.")
    print(f"APK selected: {apk} ({apk.stat().st_size:,} bytes)")
    return apk


def installed(serial: str) -> bool:
    package = adb(serial, "shell", "dumpsys", "package", PACKAGE, capture=True, check=False)
    details = package.stdout
    version_code = re.search(r"\bversionCode=(\d+)", details)
    version_name = re.search(r"\bversionName=(\S+)", details)
    if not version_code or not version_name:
        print(f"{PACKAGE}: not installed (or package information unavailable).")
        return False
    print(f"{PACKAGE}: versionCode={version_code.group(1)} versionName={version_name.group(1)}")
    return True


def install(serial: str, apk: Path) -> None:
    apk_ready(apk)
    print("Installing without erasing data (signature must match installed app)...", flush=True)
    adb(serial, "install", "-r", str(apk))
    installed(serial)


def uninstall(serial: str) -> None:
    print("WARNING: Uninstall removes Bastion Zero's local alloy, research and unlocks.", flush=True)
    print(f"Removing only {PACKAGE} from {serial}...", flush=True)
    adb(serial, "uninstall", PACKAGE)


def reinstall(serial: str, apk: Path, *, launch: bool) -> None:
    # Essential ordering: no uninstall until we know we have a valid replacement.
    apk_ready(apk)
    print("WARNING: Reset/reinstall DELETES ALL LOCAL BASTION ZERO SAVE DATA.", flush=True)
    uninstall(serial)
    adb(serial, "install", str(apk))
    installed(serial)
    if launch:
        run(serial)


def run(serial: str) -> None:
    print(f"Starting {PACKAGE} on {serial}...", flush=True)
    adb(serial, "shell", "monkey", "-p", PACKAGE, "-c", "android.intent.category.LAUNCHER", "1")


def download(apk: Path, run_id: str, artifact: str, repo: str) -> None:
    if run_id == "latest":
        # Prefer the most recent successful Android build, not a stale hardcoded
        # artifact. Developer can still pin RUN_ID=<number> when required.
        listed = execute([
            "gh", "run", "list", "--repo", repo,
            "--workflow", "android-j8.yml", "--branch", "feature/m1-playable-game",
            "--status", "success", "--limit", "1",
            "--json", "databaseId", "--jq", ".[0].databaseId"
        ], capture=True)
        run_id = listed.stdout.strip()
        print(f"Latest successful J8 CI run: {run_id}", flush=True)
    if not re.fullmatch(r"\d+", run_id):
        raise RuntimeError("RUN_ID must be 'latest' or a numeric GitHub Actions workflow run ID.")
    if not shutil.which("gh"):
        raise RuntimeError("GitHub CLI 'gh' is unavailable. Install gh and run 'gh auth login', or download the artifact manually.")
    if apk.exists():
        raise RuntimeError(f"{apk} exists already. Move it elsewhere first to avoid mixing APK versions.")
    apk.parent.mkdir(parents=True, exist_ok=True)
    execute(["gh", "run", "download", run_id, "--repo", repo, "--name", artifact, "--dir", str(apk.parent)])
    apk_ready(apk)


def logs(serial: str) -> None:
    result = adb(serial, "logcat", "-d", "-t", "350", capture=True)
    matches = [line for line in result.stdout.splitlines() if re.search(r"BastionZero|Godot|com\.dantesouza\.bastionzero|FATAL EXCEPTION", line, re.I)]
    for line in matches[-100:]:
        print(line)
    if not matches:
        print("No related entries found in last 350 log lines.")


def help_text() -> None:
    print("Bastion Zero — J8 developer commands")
    for key, info in COMMANDS.items():
        print(f"  make {key:<15} {info}")
    print("  make sync            Safely update local main/dev/feature branches from origin")
    print("  make check-tools     Check developer scripts (offline)")
    print("  make apk             Download latest successful J8 APK")
    print("  make apk RUN_ID=...  Choose a specific GitHub Actions run")
    print("  make doctor DEVICE=... APK=...  Override device or APK path")
    print("\nDefaults: DEVICE=38c19745; APK=dist/bastion-zero-j8-debug.apk")
    print("Reinstall actions are destructive for the game's local saved progress.")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", default=DEFAULT_DEVICE)
    parser.add_argument("--apk", default=DEFAULT_APK)
    parser.add_argument("command", choices=[*COMMANDS, "help"])
    parser.add_argument("--run-id", default="latest")
    parser.add_argument("--artifact", default="Bastion-Zero-M1R-J8-ARMv7")
    parser.add_argument("--repo", default="dante-souza/bastion_zero")
    args = parser.parse_args(argv)
    apk = Path(args.apk)
    if not apk.is_absolute():
        apk = ROOT / apk
    try:
        if args.command == "help":
            help_text()
        elif args.command == "download":
            download(apk, args.run_id, args.artifact, args.repo)
        else:
            device_ready(args.device)
            if args.command == "doctor":
                installed(args.device)
                if apk.is_file():
                    apk_ready(apk)
                else:
                    print(f"Local APK not found: {apk}")
            elif args.command == "installed":
                installed(args.device)
            elif args.command == "install":
                install(args.device, apk)
            elif args.command == "uninstall":
                uninstall(args.device)
            elif args.command == "reinstall":
                reinstall(args.device, apk, launch=False)
            elif args.command == "reinstall-run":
                reinstall(args.device, apk, launch=True)
            elif args.command == "run":
                run(args.device)
            elif args.command == "logs":
                logs(args.device)
    except (OSError, RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
