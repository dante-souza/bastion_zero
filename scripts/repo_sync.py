#!/usr/bin/env python3
"""Safely fast-forward Bastion Zero's local Gitflow branches; no reset/force/stash."""
from __future__ import annotations

from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
BRANCHES = ("main", "dev", "feature/m1-playable-game", "feature/m1-visual-phase-a", "feature/m1-visual-phase-b-guardian", "feature/m1-visual-phase-c-enemies", "feature/m1-visual-phase-d-weapons", "feature/m1-visual-phase-e-hud", "feature/m1-visual-phase-f-evolution", "feature/m1-visual-phase-g-identity-hangar", "feature/m1-visual-phase-h-premium", "feature/m1-visual-phase-i1-combat-hud", "feature/m1-visual-phase-i2-evolution", "feature/m1-visual-phase-i3-title-menu", "feature/m1-visual-phase-i4-threat-language", "feature/m1-visual-phase-i5-color-language", "feature/m1-visual-phase-i6-playtest-fixes")


def git(*args: str, capture: bool = True, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(ROOT), *args],
        capture_output=capture, check=check, text=True, encoding="utf-8", errors="replace",
    )


def exists(ref: str) -> bool:
    return git("show-ref", "--verify", "--quiet", ref, check=False).returncode == 0


def sync() -> int:
    original = ""
    try:
        original = git("symbolic-ref", "--quiet", "--short", "HEAD").stdout.strip()
        if not original:
            raise RuntimeError("Detached HEAD. Switch to a local branch before syncing.")
        changes = git("status", "--porcelain", "--untracked-files=normal").stdout.strip()
        if changes:
            raise RuntimeError(
                "Working tree is not clean. Commit or manually stash your local changes first.\n" + changes
            )
        git("remote", "get-url", "origin")
        print("Fetching origin and pruning stale remote refs...", flush=True)
        git("fetch", "origin", "--prune", capture=False)
        for branch in BRANCHES:
            remote = f"refs/remotes/origin/{branch}"
            local = f"refs/heads/{branch}"
            if not exists(remote):
                print(f"SKIP {branch}: no origin/{branch}")
                continue
            if exists(local):
                print(f"Updating {branch} (fast-forward only)...", flush=True)
                git("switch", branch, capture=False)
                git("merge", "--ff-only", f"origin/{branch}", capture=False)
            else:
                print(f"Tracking new local {branch}...", flush=True)
                git("switch", "--track", "-c", branch, f"origin/{branch}", capture=False)
        print("All available Gitflow branches checked. No force/reset/stash used.")
        return 0
    except (OSError, subprocess.CalledProcessError, RuntimeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    finally:
        if original:
            current = git("symbolic-ref", "--quiet", "--short", "HEAD", check=False).stdout.strip()
            if current and current != original:
                print(f"Restoring original branch: {original}", flush=True)
                back = git("switch", original, capture=False, check=False)
                if back.returncode:
                    print(f"WARNING: Could not return to {original}; inspect git status.", file=sys.stderr)


if __name__ == "__main__":
    sys.exit(sync())
