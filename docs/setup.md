# AI_SETUP_SPEC

## ENVIRONMENT
REQUIRED_SHELL: WSL bash
WORKDIR: /home/danie/projetos/cs-fan-zone
DO_NOT_USE_FOR_GIT: Git Windows over PowerShell UNC path
ROKIT_CONFIG: rokit.toml
ROJO_PROJECT: default.project.json

## COMMANDS
INSTALL_ROKIT_IF_MISSING: curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
INSTALL_TOOLS: ~/.rokit/bin/rokit install
INSTALL_PLUGIN: ~/.rokit/bin/rojo plugin install
BUILD: ~/.rokit/bin/rojo build -o build.rbxlx
SERVE: ~/.rokit/bin/rojo serve
HEALTHCHECK: curl -fsS http://127.0.0.1:34872/ >/dev/null && echo OK
GIT_STATUS: git status --short --branch
PUSH_BRANCH: git push -u origin feat/bootstrap-world

## STUDIO_MANUAL_STEPS
1. Open Roblox Studio on Windows.
2. Open the target private experience or a new place.
3. Confirm Rojo plugin has script injection permission.
4. Connect plugin to localhost:34872.
5. Run Play.
6. Validate tests/manual-smoke.md.
7. Publish privately only after release checklist passes.

## FAILURE_ROUTING
ROJO_PLUGIN_CANNOT_CONNECT: verify ~/.rokit/bin/rojo serve is running and test http://127.0.0.1:34872/.
SCRIPT_INJECTION_ERROR: enable Rojo plugin script injection permission in Studio Plugin Manager.
BUILD_ERROR: inspect the reported Luau file and run build again after fix.
STUDIO_RED_OUTPUT: capture exact error, script name, and reproduction step.
