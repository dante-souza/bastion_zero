# Local developer workflow (Windows PowerShell + Galaxy J8)

This project uses GNU Make as a convenient wrapper around two Python scripts.
**Python 3.10+**, **ADB** and **Git** must be on your Windows PATH. An authenticated
GitHub CLI (`gh`) is only necessary for automatic APK artifact downloading.

## First-time local repository refresh

From your existing project folder (for example
`M:\ATOL\GitProjects\bastion_zero`):

```powershell
git status --short --branch
git fetch origin --prune
git switch feature/m1-playable-game
git pull --ff-only origin feature/m1-playable-game
make help
make sync
```

If `git switch feature/m1-playable-game` reports the branch does not exist,
run `git switch --track origin/feature/m1-playable-game` instead. **Do not
discard local edits**: commit them or stash them deliberately before syncing.
`make sync` refuses a dirty working tree, fetches origin, updates local
`main`, `dev` and `feature/m1-playable-game` using fast-forward-only,
and restores the previously checked-out branch. It will not merge the unreviewed
feature PR into `dev` or `main`.

Check `git status -sb` after syncing. Do not use `git reset --hard` just to
resolve an ordinary local divergence.

## Get the correct M1R combat APK

The last confirmed v0.2.1 Android CI run is
[39086343483](https://github.com/dante-souza/bastion_zero/actions/runs/39086343483).
The artifact name is `Bastion-Zero-M1R-J8-ARMv7`.
Download and unzip the archive so these files are present:

```text
bastion_zero/
  dist/
    bastion-zero-j8-debug.apk
    SHA256SUMS.txt
```

`dist/` is ignored by Git; APKs are never committed. The checksum file is
recommended and checked automatically before any installation.

Alternatively, if `gh auth login` has been completed:

```powershell
make apk
# or choose a specific Actions run
make apk RUN_ID=39086343483
```

`make apk` refuses to overwrite an existing APK. Move a prior build aside first
when downloading a different run. The artifact is retained for a limited period
by GitHub Actions.

## Developer commands

| Command | Behavior |
|---|---|
| `make help` | List commands |
| `make doctor` | Check selected device, installed version and available APK |
| `make installed` | Read installed Bastion Zero version/code (no changes) |
| `make apk` | Fetch CI APK using authenticated GitHub CLI |
| `make install` | Non-destructive `adb install -r`; requires matching signature |
| `make uninstall` | **DELETES** the Bastion Zero installation and local save |
| `make reinstall` | Verify local APK, then uninstall and install (**erases save**) |
| `make reinstall-run` | Verify APK, uninstall, install and launch (**erases save**) |
| `make deploy` | Alias for `make reinstall-run` |
| `make run` | Start installed game without reinstalling |
| `make logs` | Show recent relevant logcat output |
| `make sync` | Safely fast-forward local Gitflow branches |
| `make git-status` | Show short status and local branch tracking |
| `make check-tools` | Check Python CLI scripts and run their offline unit tests |

**The default serial is `38c19745` (Samsung Galaxy J8).** Since a Moto G41
may also be connected, every ADB command is targeted explicitly. Override it
for diagnostics with `make doctor DEVICE=0077860711`.

To use a different APK path:

```powershell
make reinstall-run APK="C:/Users/dante/Downloads/bastion-zero-j8-debug.apk"
```

**Important:** CI builds currently use an ephemeral debug signing key unless
a stable `BASTION_DEBUG_KEYSTORE_BASE64` GitHub Actions secret is configured.
A signature mismatch prevents `make install` from updating; `make
reinstall-run` resolves that by uninstalling but permanently erases local game
progress. See [signing setup](ANDROID-SIGNING.md) before you start keeping
meaningful progress on the J8.
