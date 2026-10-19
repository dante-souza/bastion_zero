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
.PHONY: help profile doctor installed version apk install uninstall reinstall run reinstall-run deploy fresh logs screenshot sync git-status check-tools check phase-a phase-a-apk phase-a-install phase-a-reinstall-run phase-a-run phase-a-doctor phase-a-logs phase-a-screenshot phase-b phase-b-apk phase-b-install phase-b-reinstall-run phase-b-run phase-b-doctor phase-b-logs phase-b-screenshot phase-c phase-c-apk phase-c-install phase-c-reinstall-run phase-c-run phase-c-doctor phase-c-logs phase-c-screenshot phase-d phase-d-apk phase-d-install phase-d-reinstall-run phase-d-run phase-d-doctor phase-d-logs phase-d-screenshot phase-e phase-e-apk phase-e-install phase-e-reinstall-run phase-e-run phase-e-doctor phase-e-logs phase-e-screenshot phase-f phase-f-apk phase-f-install phase-f-reinstall-run phase-f-run phase-f-doctor phase-f-logs phase-f-screenshot phase-g phase-g-apk phase-g-install phase-g-reinstall-run phase-g-run phase-g-doctor phase-g-logs phase-g-screenshot phase-h phase-h-apk phase-h-install phase-h-reinstall-run phase-h-run phase-h-doctor phase-h-logs phase-h-screenshot phase-h-art phase-h-art-check phase-i1 phase-i1-apk phase-i1-install phase-i1-reinstall-run phase-i1-run phase-i1-doctor phase-i1-logs phase-i1-screenshot phase-i2 phase-i2-apk phase-i2-install phase-i2-reinstall-run phase-i2-run phase-i2-doctor phase-i2-logs phase-i2-screenshot phase-i3 phase-i3-apk phase-i3-install phase-i3-reinstall-run phase-i3-run phase-i3-doctor phase-i3-logs phase-i3-screenshot phase-i4 phase-i4-apk phase-i4-install phase-i4-reinstall-run phase-i4-run phase-i4-doctor phase-i4-logs phase-i4-screenshot phase-i5 phase-i5-apk phase-i5-install phase-i5-reinstall-run phase-i5-run phase-i5-doctor phase-i5-logs phase-i5-screenshot

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

# Phase H premium art + native UI, isolated Android package.
# ART_BUNDLE can be a full Windows path passed from PowerShell.
ART_BUNDLE ?=

phase-h-art:
	@$(PYTHON) scripts/phase_h_assets.py install --bundle "$(ART_BUNDLE)"

phase-h-art-check:
	@$(PYTHON) scripts/phase_h_assets.py verify --require

phase-h:
	@$(MAKE) fresh PROFILE=phase-h

phase-h-apk:
	@$(MAKE) apk PROFILE=phase-h

phase-h-install:
	@$(MAKE) install PROFILE=phase-h

phase-h-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-h

phase-h-run:
	@$(MAKE) run PROFILE=phase-h

phase-h-doctor:
	@$(MAKE) doctor PROFILE=phase-h

phase-h-logs:
	@$(MAKE) logs PROFILE=phase-h

phase-h-screenshot:
	@$(MAKE) screenshot PROFILE=phase-h

# Phase I.1 tactical HUD, built from its own branch and APK artifact.
# Reuses Phase H Android package to avoid adding another launcher icon.
phase-i1:
	@$(MAKE) fresh PROFILE=phase-i1

phase-i1-apk:
	@$(MAKE) apk PROFILE=phase-i1

phase-i1-install:
	@$(MAKE) install PROFILE=phase-i1

phase-i1-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-i1

phase-i1-run:
	@$(MAKE) run PROFILE=phase-i1

phase-i1-doctor:
	@$(MAKE) doctor PROFILE=phase-i1

phase-i1-logs:
	@$(MAKE) logs PROFILE=phase-i1

phase-i1-screenshot:
	@$(MAKE) screenshot PROFILE=phase-i1

# Phase I.2 genuine three-card evolution UI. Same premium app package.
phase-i2:
	@$(MAKE) fresh PROFILE=phase-i2

phase-i2-apk:
	@$(MAKE) apk PROFILE=phase-i2

phase-i2-install:
	@$(MAKE) install PROFILE=phase-i2

phase-i2-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-i2

phase-i2-run:
	@$(MAKE) run PROFILE=phase-i2

phase-i2-doctor:
	@$(MAKE) doctor PROFILE=phase-i2

phase-i2-logs:
	@$(MAKE) logs PROFILE=phase-i2

phase-i2-screenshot:
	@$(MAKE) screenshot PROFILE=phase-i2

# Phase I.3 tactical landing page + the I.2 J8 card typography fix.
# Installs over the same Phase H premium Android package.
phase-i3:
	@$(MAKE) fresh PROFILE=phase-i3

phase-i3-apk:
	@$(MAKE) apk PROFILE=phase-i3

phase-i3-install:
	@$(MAKE) install PROFILE=phase-i3

phase-i3-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-i3

phase-i3-run:
	@$(MAKE) run PROFILE=phase-i3

phase-i3-doctor:
	@$(MAKE) doctor PROFILE=phase-i3

phase-i3-logs:
	@$(MAKE) logs PROFILE=phase-i3

phase-i3-screenshot:
	@$(MAKE) screenshot PROFILE=phase-i3

# Phase I.4 Threat Guide and semantic warnings. Same premium app package.
phase-i4:
	@$(MAKE) fresh PROFILE=phase-i4

phase-i4-apk:
	@$(MAKE) apk PROFILE=phase-i4

phase-i4-install:
	@$(MAKE) install PROFILE=phase-i4

phase-i4-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-i4

phase-i4-run:
	@$(MAKE) run PROFILE=phase-i4

phase-i4-doctor:
	@$(MAKE) doctor PROFILE=phase-i4

phase-i4-logs:
	@$(MAKE) logs PROFILE=phase-i4

phase-i4-screenshot:
	@$(MAKE) screenshot PROFILE=phase-i4

# Phase I.5 color language: cool = yours, warm = hostile, green = XP. Same premium app package.
phase-i5:
	@$(MAKE) fresh PROFILE=phase-i5

phase-i5-apk:
	@$(MAKE) apk PROFILE=phase-i5

phase-i5-install:
	@$(MAKE) install PROFILE=phase-i5

phase-i5-reinstall-run:
	@$(MAKE) reinstall-run PROFILE=phase-i5

phase-i5-run:
	@$(MAKE) run PROFILE=phase-i5

phase-i5-doctor:
	@$(MAKE) doctor PROFILE=phase-i5

phase-i5-logs:
	@$(MAKE) logs PROFILE=phase-i5

phase-i5-screenshot:
	@$(MAKE) screenshot PROFILE=phase-i5

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
