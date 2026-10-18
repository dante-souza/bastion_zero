# Bastion Zero — Android-first workflows. All routine operations go through make.
# PROFILE=auto selects current supported Git branch; named targets work from any branch.
PYTHON ?= python
DEVICE ?= 38c19745
PROFILE ?= auto
APK ?= auto
RUN_ID ?= latest
REPO ?= dante-souza/bastion_zero
GODOT ?= godot
J8 = $(PYTHON) scripts/android_j8.py --device "$(DEVICE)" --profile "$(PROFILE)" --apk "$(APK)"

.DEFAULT_GOAL := help
.PHONY: help profile doctor installed version apk install uninstall reinstall run reinstall-run deploy fresh logs screenshot sync git-status check-tools check phase-a phase-a-apk phase-a-install phase-a-reinstall-run phase-a-run phase-a-doctor phase-a-logs phase-a-screenshot phase-b phase-b-apk phase-b-install phase-b-reinstall-run phase-b-run phase-b-doctor phase-b-logs phase-b-screenshot phase-c phase-c-apk phase-c-install phase-c-reinstall-run phase-c-run phase-c-doctor phase-c-logs phase-c-screenshot phase-d phase-d-apk phase-d-install phase-d-reinstall-run phase-d-run phase-d-doctor phase-d-logs phase-d-screenshot phase-e phase-e-apk phase-e-install phase-e-reinstall-run phase-e-run phase-e-doctor phase-e-logs phase-e-screenshot phase-f phase-f-apk phase-f-install phase-f-reinstall-run phase-f-run phase-f-doctor phase-f-logs phase-f-screenshot phase-g phase-g-apk phase-g-install phase-g-reinstall-run phase-g-run phase-g-doctor phase-g-logs phase-g-screenshot

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

screenshot:
	@$(J8) screenshot

# Explicit Phase A aliases avoid accidentally using the older M1R build.
phase-a:
	@$(MAKE) fresh PROFILE=phase-a

phase-a-apk:
	@$(MAKE) apk PROFILE=phase-a

phase-a-install:
	@$(MAKE) install PROFILE=phase-a

phase-a-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-a

phase-a-run:
	@$(MAKE) run PROFILE=phase-a

phase-a-doctor:
	@$(MAKE) doctor PROFILE=phase-a

phase-a-logs:
	@$(MAKE) logs PROFILE=phase-a

phase-a-screenshot:
	@$(MAKE) screenshot PROFILE=phase-a

# Phase B.1 Guardian / smooth-background J8 test profile.
phase-b:
	@$(MAKE) fresh PROFILE=phase-b

phase-b-apk:
	@$(MAKE) apk PROFILE=phase-b

phase-b-install:
	@$(MAKE) install PROFILE=phase-b

phase-b-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-b

phase-b-run:
	@$(MAKE) run PROFILE=phase-b

phase-b-doctor:
	@$(MAKE) doctor PROFILE=phase-b

phase-b-logs:
	@$(MAKE) logs PROFILE=phase-b

phase-b-screenshot:
	@$(MAKE) screenshot PROFILE=phase-b

# Phase C high-contrast enemy silhouettes; isolated Android package/artifact.
phase-c:
	@$(MAKE) fresh PROFILE=phase-c

phase-c-apk:
	@$(MAKE) apk PROFILE=phase-c

phase-c-install:
	@$(MAKE) install PROFILE=phase-c

phase-c-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-c

phase-c-run:
	@$(MAKE) run PROFILE=phase-c

phase-c-doctor:
	@$(MAKE) doctor PROFILE=phase-c

phase-c-logs:
	@$(MAKE) logs PROFILE=phase-c

phase-c-screenshot:
	@$(MAKE) screenshot PROFILE=phase-c

# Phase D VFX + temporary Normal 01 engine showcase.
phase-d:
	@$(MAKE) fresh PROFILE=phase-d

phase-d-apk:
	@$(MAKE) apk PROFILE=phase-d

phase-d-install:
	@$(MAKE) install PROFILE=phase-d

phase-d-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-d

phase-d-run:
	@$(MAKE) run PROFILE=phase-d

phase-d-doctor:
	@$(MAKE) doctor PROFILE=phase-d

phase-d-logs:
	@$(MAKE) logs PROFILE=phase-d

phase-d-screenshot:
	@$(MAKE) screenshot PROFILE=phase-d

# D.1 guided Lv12 showcase and E compact HUD.
phase-e:
	@$(MAKE) fresh PROFILE=phase-e

phase-e-apk:
	@$(MAKE) apk PROFILE=phase-e

phase-e-install:
	@$(MAKE) install PROFILE=phase-e

phase-e-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-e

phase-e-run:
	@$(MAKE) run PROFILE=phase-e

phase-e-doctor:
	@$(MAKE) doctor PROFILE=phase-e

phase-e-logs:
	@$(MAKE) logs PROFILE=phase-e

phase-e-screenshot:
	@$(MAKE) screenshot PROFILE=phase-e

# Phase F stress-demo + System Evolution UI, isolated J8 package.
phase-f:
	@$(MAKE) fresh PROFILE=phase-f

phase-f-apk:
	@$(MAKE) apk PROFILE=phase-f

phase-f-install:
	@$(MAKE) install PROFILE=phase-f

phase-f-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-f

phase-f-run:
	@$(MAKE) run PROFILE=phase-f

phase-f-doctor:
	@$(MAKE) doctor PROFILE=phase-f

phase-f-logs:
	@$(MAKE) logs PROFILE=phase-f

phase-f-screenshot:
	@$(MAKE) screenshot PROFILE=phase-f

# Phase G Last Horizon boot splash, icon and Hangar (separate J8 app).
phase-g:
	@$(MAKE) fresh PROFILE=phase-g

phase-g-apk:
	@$(MAKE) apk PROFILE=phase-g

phase-g-install:
	@$(MAKE) install PROFILE=phase-g

phase-g-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-g

phase-g-run:
	@$(MAKE) run PROFILE=phase-g

phase-g-doctor:
	@$(MAKE) doctor PROFILE=phase-g

phase-g-logs:
	@$(MAKE) logs PROFILE=phase-g

phase-g-screenshot:
	@$(MAKE) screenshot PROFILE=phase-g

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
