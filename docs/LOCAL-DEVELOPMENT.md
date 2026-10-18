# Bastion Zero — Makefile-first Galaxy J8 workflow

**Policy (2026-10-18):** all routine Android operations are invoked through `make`. Git and GitHub CLI commands may be used for branch management, authentication or diagnosis. Do not need to type raw ADB, Python, or Godot commands for routine operation.

## Requirements

From PowerShell in `M:\ATOL\GitProjects\bastion_zero`, have GNU Make, Python 3.10+, ADB, Git, and authenticated `gh` available in PATH. The default device is Samsung Galaxy J8 serial `38c19745`; use `DEVICE=...` to override.

## Get Phase A Makefile locally

The code lives on `feature/m1-visual-phase-a` (PR #2 targets `feature/m1-playable-game`). Switching branches is allowed; do not reset or discard local edits.

```powershell
git status --short --branch
git fetch origin --prune
git switch --track origin/feature/m1-visual-phase-a
# If branch already exists: git switch feature/m1-visual-phase-a
git pull --ff-only origin feature/m1-visual-phase-a
make help
```

`make sync` fast-forwards `main`, `dev`, M1R and Phase A safely, restoring the initial branch when finished.

## One-command Phase A installation on J8

```powershell
make phase-a
```

The target downloads the **latest successful** Phase A Android build, verifies its SHA-256 checksum, reinstalls only `com.dantesouza.bastionzero.phasea` and launches it. It does not uninstall the original M1R app.

As requested, Phase A development saves are disposable; `reinstall-run` and `phase-a` intentionally erase only the target package's saves.

## Individual routines

| Make target | Behavior |
|---|---|
| `make help` | List routines and supported profiles |
| `make profile` | Show profile selected from the current Git branch |
| `make phase-a` | Download latest Phase A, reinstall and launch |
| `make phase-a-apk` | Download/verify Phase A APK only |
| `make phase-a-doctor` | Check connected J8, installed Phase A and local APK |
| `make phase-a-install` | Update Phase A without deleting saves; matching signature required |
| `make phase-a-reinstall-run` | Reinstall cached Phase A APK and launch |
| `make phase-a-run` | Launch installed Phase A |
| `make phase-a-logs` | Inspect Android/Godot logs |
| `make phase-a-screenshot` | Capture current screen into `screenshots/` |
| `make apk` | Download selected current-branch profile's latest successful build |
| `make fresh` | Download/reinstall/launch selected current-branch profile |
| `make doctor`, `make installed` | Check selected package/J8 status |
| `make install` | Install without erasing data (signature permitting) |
| `make reinstall` | Verify/reinstall, deleting only selected package's saves |
| `make reinstall-run`, `make deploy` | Reinstall and launch cached APK |
| `make run` | Launch selected package |
| `make logs`, `make screenshot` | Diagnostics and PNG capture |
| `make sync` | Update local branches via fast-forward only |
| `make check-tools`, `make check` | Local Python/Godot tests |
| `make git-status` | Print local Git branch and status |

Profiles are `phase-a` and `m1r`; `PROFILE=auto` selects the matching current Git branch or fails closed if unsupported. The Android package is never chosen independently of the profile.

`make apk` places builds in distinct directories so older `dist/bastion-zero-j8-debug.apk` cannot interfere:

```text
dist/
  m1r/bastion-zero-j8-debug.apk
  phase-a/bastion-zero-phase-a-j8-debug.apk
```

Each directory also contains a `SHA256SUMS.txt` and a cached run-id. Re-running `make apk` against the same successful run verifies and reuses the existing APK; when a new run succeeds, the target downloads and replaces only that profile's cached artifact.

## Use the already downloaded Phase A APK

The artifact downloaded manually to `C:\Users\dante\Downloads\BastionZero-PhaseA` can be installed via **Make**, too:

```powershell
make phase-a-reinstall-run APK="C:/Users/dante/Downloads/BastionZero-PhaseA/bastion-zero-phase-a-j8-debug.apk"
```

Its `SHA256SUMS.txt` should be alongside the APK. The standard `make phase-a` workflow is preferred going forward.

## Select a specific successful run

```powershell
make phase-a-apk RUN_ID=39149399652
make phase-a-reinstall-run
```

The helper verifies the selected run belongs to Phase A and refuses a different branch's artifact.

## Build signing

Unless `BASTION_DEBUG_KEYSTORE_BASE64` is configured in GitHub Actions, the CI workflow signs each APK with an ephemeral key. Android will reject in-place upgrades with mismatching certificates. Use `make phase-a` (reinstall) until stable signing and meaningful save persistence become requirements. See `docs/ANDROID-SIGNING.md`.
