# AI_SETUP_SPEC

WORKDIR: /home/danie/projetos/cs-fan-zone
REQUIRED_SHELL: WSL bash
BUILD: ~/.rokit/bin/rojo build -o build.rbxlx
SERVE: ~/.rokit/bin/rojo serve
HEALTHCHECK: curl -fsS http://127.0.0.1:34872/ >/dev/null && echo OK

## STUDIO
1. Abrir Roblox Studio.
2. Garantir permissao de script injection para Rojo.
3. Conectar em localhost:34872.
4. Rodar Play.
5. Confirmar spawn no lobby terrestre e HUD de onboarding.
6. Validar tests/manual-smoke.md.
