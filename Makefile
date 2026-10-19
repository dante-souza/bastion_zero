# Bastion Zero — Android-first workflows. All routine operations go through make.
# PROFILE=auto derives the build from the current Git branch (any branch);
# phase-* targets fetch the frozen per-phase builds.
PYTHON ?= python
DEVICE ?= 38c19745
PROFILE ?= auto
APK ?= auto
RUN_ID ?= latest
REPO ?= dante-souza/bastion_zero
COUNT ?= 30
GODOT ?= godot
J8 = $(PYTHON) scripts/android_j8.py --device "$(DEVICE)" --profile "$(PROFILE)" --apk "$(APK)"

.DEFAULT_GOAL := help
.PHONY: help profile doctor installed version apk install uninstall reinstall run reinstall-run deploy fresh logs perf perf-clean enemies screenshot sync git-status check-tools check sim-sectors phase-h-art phase-h-art-check

help:
	@$(J8) help

profile:
	@$(J8) profile

doctor:
	@$(J8) doctor

installed version:
	@$(J8) installed

apk:
	@$(J8) download --run-id "$(RUN_ID)" --repo "$(REPO)"

install:
	@$(J8) install

uninstall:
	@$(J8) uninstall

reinstall:
	@$(J8) reinstall

run:
	@$(J8) run

# Destructive for the selected package's local save only.
reinstall-run deploy:
	@$(J8) reinstall-run

# Fresh build: fetch most recent successful APK, reinstall and launch.
fresh:
	@$(MAKE) apk PROFILE="$(PROFILE)"
	@$(MAKE) reinstall-run PROFILE="$(PROFILE)"

logs:
	@$(J8) logs

# Perf probe lines straight from logcat (PowerShell). Clear before a run,
# read after it; `make enemies COUNT=30` keeps only lines with that many enemies.
perf-clean: SHELL := powershell.exe
perf-clean:
	@adb -s $(DEVICE) logcat -c

perf: SHELL := powershell.exe
perf:
	@adb -s $(DEVICE) logcat -d -s godot | Select-String "BastionZero perf"

enemies: SHELL := powershell.exe
enemies:
	@adb -s $(DEVICE) logcat -d -s godot | Select-String "BastionZero perf" | ForEach-Object { if ($$_ -match 'enemies\s*[:=]\s*(?<count>\d+)' -and [int]$$Matches.count -ge $(COUNT)) { $$_ } }

screenshot:
	@$(J8) screenshot

# Frozen phase builds (phase-a ... phase-i6) keep their own packages and
# artifacts; one pattern per action replaces the per-phase copies. Specific
# patterns come first so older GNU make (3.81) also picks them.
phase-h-art:
	@$(PYTHON) scripts/phase_h_assets.py install --bundle "$(ART_BUNDLE)"

phase-h-art-check:
	@$(PYTHON) scripts/phase_h_assets.py verify --require

phase-%-apk:
	@$(MAKE) apk PROFILE=phase-$*

phase-%-install:
	@$(MAKE) install PROFILE=phase-$*

phase-%-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-$*

phase-%-run:
	@$(MAKE) run PROFILE=phase-$*

phase-%-doctor:
	@$(MAKE) doctor PROFILE=phase-$*

phase-%-logs:
	@$(MAKE) logs PROFILE=phase-$*

phase-%-screenshot:
	@$(MAKE) screenshot PROFILE=phase-$*

phase-%:
	@$(MAKE) fresh PROFILE=phase-$*

# Fast-forward only; no reset, forced checkout or stash.
sync:
	@$(PYTHON) scripts/repo_sync.py

git-status:
	@git status --short --branch
	@git branch -vv

check-tools:
	@$(PYTHON) -m compileall -q scripts
	@$(PYTHON) -m unittest discover -s tests -p "test_devtools.py" -v

check: check-tools
	@$(GODOT) --headless --path . --editor --quit --quit-after 240
	@$(GODOT) --headless --path . --script res://tests/test_smoke.gd
	@$(GODOT) --headless --path . --quit-after 10

# Headless balance probe: a bot plays every sector at LV1 and HARD START.
sim-sectors:
	@$(GODOT) --headless --path . --script res://tests/sim_sectors.gd
