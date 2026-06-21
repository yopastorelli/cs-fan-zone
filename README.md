# CS Fan Zone

## AI_CONTEXT
PROJECT_TYPE: Roblox Rojo experience
PRIMARY_GOAL: Exploration MVP with 12 unique collectibles, 3 server-authoritative POIs, and a final celebration room.
CURRENT_BRANCH: feat/bootstrap-world
LOCAL_ROOT_WSL: /home/danie/projetos/cs-fan-zone
TOOLCHAIN: Rokit + Rojo
BUILD_COMMAND: ~/.rokit/bin/rojo build -o build.rbxlx
SERVE_COMMAND: ~/.rokit/bin/rojo serve
STUDIO_CONNECT: Rojo plugin -> localhost:34872

## ARCHITECTURE
SHARED_CONFIG: src/Shared/Config.lua
WORLD_DATA: src/Shared/WorldData.lua
REMOTE_CONTRACTS: src/Shared/Remotes.lua
PURE_COUNTER: src/Shared/Counter.lua
WORLD_BOOTSTRAP: src/Server/WorldBootstrap.server.lua
MISSION_STATE: src/Server/MissionState.lua
COLLECTIBLE_RULES: src/Server/CollectibleService.server.lua
POI_RULES: src/Server/PoiService.server.lua
FINAL_GATE_RULES: src/Server/FinalGateService.server.lua
CLIENT_HUD: src/Client/HUD.client.lua
CLIENT_FEEDBACK: src/Client/CollectibleFeedback.client.lua

## GAMEPLAY_CONTRACT
SPAWN: Player starts in CentralPlaza.
OBJECTIVE: Collect 12 memories and activate 3 POIs.
AUTHORITY: Server owns collection, POI activation, mission completion, and final room access.
CLIENT_ALLOWED: HUD rendering and local visual feedback only.
FINAL_ROOM: FinalGate stays physically blocked; FinalGatePrompt teleports only completed players.
FIRST_COLLECTIBLE_TARGET: reachable in less than 60 seconds.
FULL_LOOP_TARGET: 5 to 10 minutes.

## COMPLIANCE_CONTRACT
NO_REAL_NAMES: true
NO_OFFICIAL_LOGOS: true
NO_VOICES_OR_VIDEO_FRAMES: true
NO_EXACT_SLOGANS: true
NO_RECOGNIZABLE_AVATARS: true
NO_OFF_PLATFORM_LINKS: true
NO_PERSONAL_DATA_COLLECTION: true
EXTERNAL_ASSET_REGISTER_REQUIRED: docs/asset-register.md
ATTRIBUTION_REQUIRED: docs/ATTRIBUTIONS.md

## VALIDATION_SEQUENCE
1. cd /home/danie/projetos/cs-fan-zone
2. git status --short --branch
3. ~/.rokit/bin/rojo build -o build.rbxlx
4. ~/.rokit/bin/rojo serve
5. curl -fsS http://127.0.0.1:34872/ >/dev/null
6. Connect Roblox Studio Rojo plugin to localhost:34872
7. Run Play and execute tests/manual-smoke.md
