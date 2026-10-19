# Bastion Zero — Makefile-first Galaxy J8 workflow

**Policy (2026-10-18):** all routine Android operations are invoked through `make`. Git and GitHub CLI commands may be used for branch management, authentication or diagnosis. Do not need to type raw ADB, Python, or Godot commands for routine operation.

## Requirements

From PowerShell in `M:\ATOL\GitProjects\bastion_zero`, have GNU Make, Python 3.10+, ADB, Git, and authenticated `gh` available in PATH. The default device is Samsung Galaxy J8 serial `38c19745`; use `DEVICE=...` to override.

## Any branch: one build profile (2026-10-19)

Every branch except the frozen phase branches (`dev`, `main`, any
`feature/...`) now builds the same way. A push runs **Android J8 debug APK**
with the single `Android J8 Branch Debug` preset and uploads artifact
`Bastion-Zero-J8-ARMv7`. The app installs over the premium package
(`com.dantesouza.bastionzero.phaseh`, the same one Phase H–I6 used), so the J8
keeps one Bastion Zero icon. CI stamps versionCode `1000 + run number` and a
versionName like `0.9.5-playtest-fixes-feature-perf-baseline-1a2b3c4`, so
`make installed` shows which branch and commit is on the phone.

```powershell
git fetch origin --prune
git switch --track origin/<branch>   # or: git switch <branch>; git merge --ff-only origin/<branch>
make profile        # shows the branch profile and APK path (dist/<branch-slug>/)
make fresh          # latest successful APK of THIS branch: download, verify, reinstall, launch
make doctor
make screenshot
make logs           # includes the "BastionZero perf:" lines (last 350 log lines only)
make perf-clean     # clear the phone log before a perf run
make perf           # every "BastionZero perf:" line since the last perf-clean
make enemies        # only perf lines with enemies >= COUNT (default 30)
```

New branches need no Make target, preset or workflow edit. `PROFILE=<branch>`
works from any checkout (for example `make fresh PROFILE=dev`).

The frozen phase builds stay reachable with `make phase-a` … `make phase-i6`
(plus `-apk`, `-install`, `-reinstall-run`, `-run`, `-doctor`, `-logs`,
`-screenshot`). Those branches keep their own copy of the workflow, and
their CI artifacts expire after 30 days.

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

Profiles are `phase-b`, `phase-a` and `m1r`; `PROFILE=auto` selects the matching current Git branch or fails closed if unsupported. The Android package is never chosen independently of the profile.

`make apk` places builds in distinct directories so older `dist/bastion-zero-j8-debug.apk` cannot interfere:

```text
dist/
  m1r/bastion-zero-j8-debug.apk
  phase-a/bastion-zero-phase-a-j8-debug.apk
  phase-b/bastion-zero-phase-b-j8-debug.apk
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

## Phase B.1 — selected circular Guardian and smooth backdrop

Phase B.1 continues Phase A on `feature/m1-visual-phase-b-guardian`, with its own
APK profile, `com.dantesouza.bastionzero.phaseb`. Select it once:

```powershell
git status --short --branch
git fetch origin --prune
git switch --track origin/feature/m1-visual-phase-b-guardian
# If your local branch already exists: git switch feature/m1-visual-phase-b-guardian
git pull --ff-only origin feature/m1-visual-phase-b-guardian
```

All *device* operations are Makefile targets:

```powershell
make check-tools
make phase-b
make phase-b-doctor
make phase-b-screenshot
make phase-b-logs
```

`make phase-b` downloads the latest **successful Phase B J8** workflow artifact,
verifies SHA-256, reinstalls the dedicated Phase B package and launches it. The
old `dist/bastion-zero-j8-debug.apk`, Phase A APK, and their saves cannot be
confused with Phase B. Development saves for Phase B can be erased.

Other Phase B targets: `make phase-b-apk`, `make phase-b-install`,
`make phase-b-reinstall-run`, `make phase-b-run` and
`make phase-b-screenshot`. On the Phase B branch, `make fresh` and
`make apk` auto-select Phase B as well.

See [Guardian Phase B.1 technical notes](VISUAL-PHASE-B1.md). The selected
reference image is **not** copied into the APK; all in-game art is procedural.

## Phase C — enemy geometry and visual clarity

This release lives on `feature/m1-visual-phase-c-enemies` (stacked on Phase B)
and uses a **separate** `com.dantesouza.bastionzero.phasec` Android package.
After fetching the branch, all J8 commands remain Make-only:

```powershell
make profile
make check-tools
make phase-c
make phase-c-doctor
make phase-c-screenshot
make phase-c-logs
```

`make phase-c` fetches only a **successful Phase C** GitHub Actions run;
it verifies the matching artifact checksum, caches under `dist/phase-c/`,
reinstalls the Phase C app and launches. Only Phase C saves are erased.
`make phase-c-apk`, `make phase-c-reinstall-run` and `make phase-c-run`
are available for shorter loops. See [Phase C](VISUAL-PHASE-C.md).

## Phase D — all weapons + temporary NORMAL 01 showcase

Branch `feature/m1-visual-phase-d-weapons` extends Phase C and uses isolated
`com.dantesouza.bastionzero.phased` Android package and
`Bastion-Zero-Phase-D-J8-ARMv7` CI artifact.

On NORMAL 01 only, the build deliberately starts the Guardian at **LEVEL 7**
with Sentinel rank 3, Prism/Comet/Arc/Nova rank 1, initial mixed enemies and
an early elite visual inspection encounter. Stage 2 and ordinary Arena callers
keep their normal starting rules. This is a temporary debug-mode gameplay
fixture; it is not the intended final economy/balance.

After switching to the Phase D branch, **all device operations use Make**:

```powershell
make profile
make check-tools
make check
make phase-d
make phase-d-doctor
make phase-d-screenshot
make phase-d-logs
```

`make phase-d` selects the latest successful *Phase D* Android workflow run,
verifies the SHA-256, downloads to `dist/phase-d/`, reinstalls its isolated
package and launches. Saves are disposable. See [Phase D](VISUAL-PHASE-D.md).

## D.1 + E: level-12 demo and compact HUD

Phase E is stacked on Phase D in `feature/m1-visual-phase-e-hud` with
an isolated J8 package `com.dantesouza.bastionzero.phasee` and APK cache
in `dist/phase-e/`.

NORMAL 01 uses higher test starting ranks and guided targets at seconds
0/4/8/12/20; standard wave formations resume at second 24. Top HUD is
106 logical px (was 150); bottom HUD is 80 px (was 110).

```powershell
make profile
make check-tools
make check
make phase-e
make phase-e-doctor
make phase-e-screenshot
make phase-e-logs
```

Progress can be erased in this debug package. See `docs/VISUAL-PHASE-E.md`.

## Phase F — pressure stress test and tactical System Evolution

Phase F branch: `feature/m1-visual-phase-f-evolution`, stacked on Phase E.
The Android build installs separately as `com.dantesouza.bastionzero.phasef`
and caches under `dist/phase-f/`.

NORMAL 01 visual QA starts with nine enemies, delivers five larger scripted
follow-up groups, and runs original formations every approximately 1.2 sec
from 12 sec. Extra enemy HP, speed and breach damage affect only the QA
showcase; regular NORMAL 01 and ELITE 01 rules are untouched. Upgrade selection
now uses weapon-specific accent colors and true current/next rank progress.

```powershell
make profile
make check-tools
make check
make phase-f
make phase-f-doctor
make phase-f-screenshot
make phase-f-logs
```

`make phase-f` uses the latest successful Phase F GitHub Actions build,
verifies SHA-256, reinstalls and launches on the J8. Development saves
remain disposable. See `docs/VISUAL-PHASE-F.md`.

## Phase G — The Last Horizon identity and Hangar

Branch `feature/m1-visual-phase-g-identity-hangar`, stacked on Phase F.
The new branded dark-navy Android boot splash, Guardian icon and illustrated
hangar ship as one ARMv7 APK. The original real combat and Phase F stress demo
remain available. The hangar's deployment, research, FX and save data actions
continue through their real signal handlers.

Phase G package: `com.dantesouza.bastionzero.phaseg`, cached at
`dist/phase-g/`. Device operations stay Makefile-only:

```powershell
make profile
make check-tools
make check
make phase-g
make phase-g-doctor
make phase-g-screenshot
make phase-g-logs
```

`make phase-g` verifies the latest successful Phase G CI APK's SHA256 before
reinstalling and launching. Phase G test saves are disposable. For launch-logo
review, observe the *actual cold start* as well as the Hangar and launcher icon.
See `docs/VISUAL-PHASE-G.md` for acceptance criteria and asset provenance.

## Phase H — premium art and native cinematic Hangar

Branch: `feature/m1-visual-phase-h-premium`, stacked on Phase G. Android
package: `com.dantesouza.bastionzero.phaseh`.

The six final, approved premium images (splash, hero, atmospheric background,
launcher/adaptive icons) are **tracked in GitHub**. The project and Phase H
Android export preset already point to the premium assets. There is no
separate asset-import/download step required for developers.

```powershell
git fetch origin --prune
git switch feature/m1-visual-phase-h-premium
git merge --ff-only origin/feature/m1-visual-phase-h-premium
make profile
make check-tools
make phase-h
make phase-h-doctor
make phase-h-screenshot
```

`make phase-h` selects a successful *Phase H* CI APK, verifies checksum,
reinstalls and launches the isolated J8 package. CI verifies the exact
premium image SHA-256 values and performs the Godot import/build. Local
`make check` requires a local Godot executable; it is optional for J8
deployment because the remote CI has equivalent Godot checks.

`make phase-h-art` is retained only for replacing the approved images in
future art revisions, not for Phase H installation. See
`docs/VISUAL-PHASE-H.md`.

## Phase I.1 — Tactical Combat HUD (same Phase H Android package)

Reference: user's four-screen tactical mockup. On branch
`feature/m1-visual-phase-i1-combat-hud`, the game gains a compact wave/time,
real formation warning and live-elite health strip, plus five weapon rank
slots. The J8 APK uses `com.dantesouza.bastionzero.phaseh`, preserving a single
premium Guardian launcher icon rather than introducing another app.

```powershell
git fetch origin --prune
git switch feature/m1-visual-phase-i1-combat-hud
git merge --ff-only origin/feature/m1-visual-phase-i1-combat-hud
make profile
make check-tools
make phase-i1
make phase-i1-doctor
make phase-i1-screenshot
```

GitHub CI builds with Godot 4.4.1 and checks the existing six premium images.
Local Godot remains optional. `make phase-i1` replaces the existing Phase H
app build and can reset its disposable debug saves.

## Phase I.2 — Tactical Level-Up Choice

Branch `feature/m1-visual-phase-i2-evolution`, stacked on I.1. Uses the
**same premium Phase H package** `com.dantesouza.bastionzero.phaseh`;
Android version code 21 / `0.9.1-phase-i2-levelup-debug`. Three real upgrade
cards replace the older oversized evolution panel; test by leveling up in
Normal 01.

```powershell
git fetch origin --prune
git switch feature/m1-visual-phase-i2-evolution
git merge --ff-only origin/feature/m1-visual-phase-i2-evolution
make profile
make check-tools
make phase-i2
make phase-i2-doctor
make phase-i2-screenshot
```

Assets remain directly committed to GitHub, and CI still performs Godot
checks and APK export. Local Godot is not required.

## Phase I.3 — Tactical Title/Menu + readable I.2 cards

The default landing view on `feature/m1-visual-phase-i3-title-menu` is a
reference-inspired BASTION/ZERO wordmark, original Guardian, defensive horizon,
primary deploy control and HANGAR/SECTORS/SETTINGS navigation. All buttons
are native and functional; Hangar still hosts alloy research, Sectors opens
live stage selection, and Settings changes the persisted LOW/FULL flag.
The I.2 J8 font corrections are included; CHOOSE ONE is unchanged (39).

Android J8 version `0.9.2-phase-i3-title-menu-debug`, version code 22, same
premium `com.dantesouza.bastionzero.phaseh` package. Source and full approved
art reside on GitHub; no manual downloads or local Godot are needed.

```powershell
git fetch origin --prune
git switch feature/m1-visual-phase-i3-title-menu
git merge --ff-only origin/feature/m1-visual-phase-i3-title-menu
make profile
make check-tools
make phase-i3
make phase-i3-screenshot
```

## Phase I.4 — Threat Language / Field Guide

Branch `feature/m1-visual-phase-i4-threat-language`, stacked on I.3.
An offline native Threat Guide explains the original four hostile shapes and
actual status effects. Reach it from Title or Pause; returning from Pause
keeps the battle paused. HUD warning colors now reflect live elite,
armored, breach and incoming events, without adding mechanics.

J8 ARMv7 version `0.9.3-phase-i4-threat-language-debug`, code 23, same
`com.dantesouza.bastionzero.phaseh` premium app package. Source/art on
GitHub, local Godot not required:

```powershell
git fetch origin --prune
git switch feature/m1-visual-phase-i4-threat-language
git merge --ff-only origin/feature/m1-visual-phase-i4-threat-language
make profile
make check-tools
make phase-i4
make phase-i4-doctor
make phase-i4-screenshot
```

## Phase I.5 — Color Language

Branch `feature/m1-visual-phase-i5-color-language`, stacked on I.4.
Palette pass only: cool = yours, warm = hostile, green = XP. Typed HUD
event kinds replace text matching. No mechanics or balance changes.

J8 ARMv7 version `0.9.4-phase-i5-color-language-debug`, code 24, same
`com.dantesouza.bastionzero.phaseh` premium app package:

```powershell
git fetch origin --prune
git switch --track origin/feature/m1-visual-phase-i5-color-language
git merge --ff-only origin/feature/m1-visual-phase-i5-color-language
make profile
make check-tools
make phase-i5
make phase-i5-screenshot
make phase-i5-doctor
```

## Phase I.6 — Playtest Fixes

Branch `feature/m1-visual-phase-i6-playtest-fixes`, stacked on I.5.
Compact combat HUD, level-up card fixes, health-bar and kill-pop clutter,
Android back navigation. No mechanics or balance changes.

J8 ARMv7 version `0.9.5-phase-i6-playtest-fixes-debug`, code 25, same
`com.dantesouza.bastionzero.phaseh` premium app package:

```powershell
git fetch origin --prune
git switch --track origin/feature/m1-visual-phase-i6-playtest-fixes
git merge --ff-only origin/feature/m1-visual-phase-i6-playtest-fixes
make profile
make check-tools
make phase-i6
make phase-i6-screenshot
make phase-i6-doctor
```
