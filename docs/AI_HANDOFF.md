# AI_HANDOFF

## CURRENT_STATE
BRANCH: feat/bootstrap-world
STATUS: Exploration MVP implemented locally.
BUILD_ARTIFACT: build.rbxlx
PRIMARY_VALIDATION_DONE: rojo build
MANUAL_STUDIO_VALIDATION: pending user playtest

## CRITICAL_INVARIANTS
- Keep all operational commands in WSL at /home/danie/projetos/cs-fan-zone.
- Preserve default.project.json mappings for src/Shared, src/Server, and src/Client.
- Server remains authoritative for mission progress and final room access.
- Client scripts may only render HUD and local visual feedback.
- No direct third-party IP, names, logos, voices, video frames, slogans, likenesses, links, QR codes, email prompts, or data collection.

## IMPORTANT_FILES
- src/Shared/Config.lua: mission constants, areas, collectibles, POIs, UI, audio, compliance.
- src/Shared/WorldData.lua: procedural world layout and content data.
- src/Server/WorldBootstrap.server.lua: generates Workspace.CSFanZone.
- src/Server/MissionState.lua: per-player state and remote updates.
- src/Server/FinalGateService.server.lua: validates final room entry.
- src/Client/HUD.client.lua: player HUD.
- src/Client/CollectibleFeedback.client.lua: local per-player visual feedback.
- tests/manual-smoke.md: Studio validation script for humans/agents controlling Studio.

## NEXT_TEST_SEQUENCE
1. Start `~/.rokit/bin/rojo serve` from WSL.
2. Connect Roblox Studio Rojo plugin to localhost:34872.
3. Run Play.
4. Execute every CHECK in tests/manual-smoke.md.
5. If all pass, publish privately only.
