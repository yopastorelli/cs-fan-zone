# AI_RELEASE_CHECKLIST

## TECHNICAL_GATES
- [ ] WSL command `git status --short --branch` shows intended branch and no unknown unrelated work.
- [ ] WSL command `~/.rokit/bin/rojo build -o build.rbxlx` succeeds.
- [ ] WSL command `~/.rokit/bin/rojo serve` starts server on 127.0.0.1:34872.
- [ ] HTTP healthcheck `curl -fsS http://127.0.0.1:34872/ >/dev/null` succeeds.
- [ ] Roblox Studio Rojo plugin sync completes without script injection error.
- [ ] Studio Output has zero red errors after 2 minutes of Play.

## GAMEPLAY_GATES
- [ ] Player spawns in CentralPlaza.
- [ ] HUD shows objective, Memorias 0/12, POIs 0/3, and Ritual status.
- [ ] First collectible is reachable in less than 60 seconds.
- [ ] 12 unique collectibles can be collected exactly once per player.
- [ ] 3 unique POIs can be activated exactly once per player.
- [ ] FinalGate cannot be bypassed before mission completion.
- [ ] FinalGatePrompt denies incomplete players with a HUD message.
- [ ] FinalGatePrompt teleports complete players into FinalCelebrationRoom.
- [ ] Final room gives visible payoff suitable for screenshot.
- [ ] Full MVP loop takes 5 to 10 minutes.

## COMPLIANCE_GATES
- [ ] Experience remains private until compliance review is complete.
- [ ] No real names, official logos, voices, screenshots, copied slogans, or recognizable avatars without license.
- [ ] No off-platform links, QR codes, Discord prompts, email requests, or personal-data collection.
- [ ] `docs/asset-register.md` lists every external asset.
- [ ] `docs/ATTRIBUTIONS.md` includes all required credits.
- [ ] Name review: nothing can be confused with an official brand or title.
- [ ] Text review: no exact slogan, catchphrase, quote, or named cast reference.
- [ ] Visual review: no logo, thumbnail, costume, banner, icon, or likeness too close to a protected source.
- [ ] Audio review: no recognizable theme, voice, sample, or effect tied to a real brand or person.
- [ ] UI review: palette, composition, and framing do not imply official endorsement or origin.

## SHIP_DECISION
SHIP_PRIVATE: all TECHNICAL_GATES and GAMEPLAY_GATES pass, COMPLIANCE_GATES pass, and docs are current.
DO_NOT_SHIP: any gate fails or any external asset lacks clear source/license/attribution.
