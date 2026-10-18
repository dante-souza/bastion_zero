# Bastion Zero developer commands (GNU Make + Python + ADB).
# Device is pinned: the Moto G41 may be connected at the same time.
PYTHON ?= python
DEVICE ?= 38c19745
APK ?= dist/bastion-zero-j8-debug.apk
RUN_ID ?= 39086343483
ARTIFACT ?= Bastion-Zero-M1R-J8-ARMv7
REPO ?= dante-souza/bastion_zero
ADB_CMD = $(PYTHON) scripts/android_j8.py --device "$(DEVICE)" --apk "$(APK)"

.DEFAULT_GOAL := help
.PHONY: help doctor installed version apk install uninstall reinstall run reinstall-run deploy logs sync git-status check-tools

help:
	@$(PYTHON) scripts/android_j8.py help

doctor:
	@$(ADB_CMD) doctor

installed version:
	@$(ADB_CMD) installed

apk:
	@$(ADB_CMD) download --run-id "$(RUN_ID)" --artifact "$(ARTIFACT)" --repo "$(REPO)"

install:
	@$(ADB_CMD) install

uninstall:
	@$(ADB_CMD) uninstall

reinstall:
	@$(ADB_CMD) reinstall

run:
	@$(ADB_CMD) run

# Explicitly destructive: requires APK preflight before removing old app/data.
reinstall-run deploy:
	@$(ADB_CMD) reinstall-run

logs:
	@$(ADB_CMD) logs

# Fast-forward only, never stash/reset/force-push or auto-merge unrelated branches.
sync:
	@$(PYTHON) scripts/repo_sync.py

git-status:
	@git status --short --branch
	@git branch -vv

check-tools:
	@$(PYTHON) -m compileall -q scripts
	@$(PYTHON) -m unittest discover -s tests -p "test_devtools.py" -v
