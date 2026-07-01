# CS Fan Zone Arena

## AI_CONTEXT
PROJECT_TYPE: Roblox Rojo competitive arena
PRIMARY_GOAL: MVP adaptativo com 1v1 ate 3 jogadores, duplas com 4+, seis biomas originais, defesa de base segura, exploracao e leitura simples.
LOCAL_ROOT_WSL: /home/danie/projetos/cs-fan-zone
BUILD_COMMAND: ~/.rokit/bin/rojo build -o build.rbxlx
SERVE_COMMAND: ~/.rokit/bin/rojo serve
STUDIO_CONNECT: Rojo plugin -> localhost:34872

## GAMEPLAY
MODE: arena competitiva adaptativa: 1v1 com 2-3 jogadores elegiveis, duplas com 4+
TEAMS: Planicie, Deserto, Taiga, Selva, Neve, Cogumelos
OBJECTIVE: destruir o totem inimigo e ser o ultimo time vivo
PLAYER_PHASES: Lobby, InMatch, Spectating
FEATURES: onboarding no lobby, geradores, loja, upgrades, blocos, espada, picareta, respawn, eliminacao final e empate
VISUAL_SYSTEMS: VisualKit, WorldBuilder, EnvironmentService
PREMIUM_TARGET: lobby cinematico, biomas com silhueta propria, centro premium, HUD mobile-first

## SAFETY
LICENSED_REAL_NAMES: false
NO_OFFICIAL_LOGOS: true
NO_THIRD_PARTY_IP: true
NO_OFF_PLATFORM_LINKS: true
LICENSE_SCOPE: fictional team and biome labels only; logos, voices, slogans, real names, and branded media remain disallowed

## VALIDATION
1. cd /home/danie/projetos/cs-fan-zone
2. ~/.rokit/bin/rojo build -o build.rbxlx
3. ~/.rokit/bin/rojo serve
4. curl -fsS http://127.0.0.1:34872/ >/dev/null
5. Conectar Rojo no Studio
6. Rodar Play e executar tests/manual-smoke.md
