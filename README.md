# CS Fan Zone Arena

## AI_CONTEXT
PROJECT_TYPE: Roblox Rojo competitive arena
PRIMARY_GOAL: 6 duplas, uma por bioma em portugues, com loop BedWars-like seguro, original e visual premium.
LOCAL_ROOT_WSL: /home/danie/projetos/cs-fan-zone
BUILD_COMMAND: ~/.rokit/bin/rojo build -o build.rbxlx
SERVE_COMMAND: ~/.rokit/bin/rojo serve
STUDIO_CONNECT: Rojo plugin -> localhost:34872

## GAMEPLAY
MODE: arena competitiva 6x2
TEAMS: Planicie, Deserto, Taiga, Selva, Neve, Cogumelos
OBJECTIVE: destruir o nucleo das outras duplas e ser a ultima dupla viva
PLAYER_PHASES: Lobby, InMatch, Spectating
FEATURES: onboarding no lobby, geradores, loja, upgrades, blocos, espada, picareta, respawn, eliminacao final e empate
VISUAL_SYSTEMS: VisualKit, WorldBuilder, EnvironmentService
PREMIUM_TARGET: lobby cinematico, biomas com silhueta propria, centro premium, HUD mobile-first

## SAFETY
LICENSED_REAL_NAMES: true
NO_OFFICIAL_LOGOS: true
NO_THIRD_PARTY_IP: true
NO_OFF_PLATFORM_LINKS: true
LICENSE_SCOPE: roster names only; logos, voices, slogans, and branded media remain disallowed

## VALIDATION
1. cd /home/danie/projetos/cs-fan-zone
2. ~/.rokit/bin/rojo build -o build.rbxlx
3. ~/.rokit/bin/rojo serve
4. curl -fsS http://127.0.0.1:34872/ >/dev/null
5. Conectar Rojo no Studio
6. Rodar Play e executar tests/manual-smoke.md
