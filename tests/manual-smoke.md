# AI_MANUAL_SMOKE_SPEC

## PRECHECK_WSL
COMMAND_1: cd /home/danie/projetos/cs-fan-zone
COMMAND_2: git status --short --branch
COMMAND_3: ~/.rokit/bin/rojo --version
COMMAND_4: ~/.rokit/bin/rojo build -o build.rbxlx
COMMAND_5: ~/.rokit/bin/rojo serve
COMMAND_6: curl -fsS http://127.0.0.1:34872/ >/dev/null && echo OK

## STUDIO_EXPECTED_WORLD
CHECK: Workspace.CSFanZone exists.
CHECK: Areas exist: CentralPlaza, NostalgiaWall, ClipStage, MemeLounge, FinalCelebrationRoom.
CHECK: Player spawns in CentralPlaza.
CHECK: FinalGate blocks physical access before mission completion.
CHECK: FinalGatePrompt exists on FinalGate.

## STUDIO_EXPECTED_HUD
CHECK: HUD title is CS Fan Zone.
CHECK: Objective text is visible.
CHECK: Memorias starts at 0/12.
CHECK: POIs starts at 0/3.
CHECK: Ritual status starts as Explorando.
CHECK: HUD remains readable on desktop viewport.
CHECK: HUD remains readable on mobile-sized viewport.

## STUDIO_EXPECTED_MISSION
CHECK: First collectible is found in less than 60 seconds.
CHECK: Each unique collectible increments leaderstats.Memories once.
CHECK: Duplicate collectible does not increment leaderstats.Memories.
CHECK: Each unique POI increments leaderstats.POIs once.
CHECK: Duplicate POI does not increment leaderstats.POIs.
CHECK: 12 memories plus 3 POIs sets player attribute MissionComplete to true.
CHECK: Collected collectibles fade locally for that player.
CHECK: Activated POIs turn visually complete locally for that player.
CHECK: Incomplete player using FinalGatePrompt receives blocked message.
CHECK: Complete player using FinalGatePrompt teleports into FinalCelebrationRoom.
CHECK: Final room visual feedback activates for complete player.
CHECK: Full loop completes in 5 to 10 minutes.
CHECK: Studio Output has zero red errors after 2 minutes.

## ACCEPTANCE
PASS_CONDITION: all CHECK lines above pass.
FAIL_CONDITION: any red Output error, missing area, incorrect counter, bypassable final room, or direct IP/compliance issue.
