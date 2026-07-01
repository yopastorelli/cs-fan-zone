# FTUE Audit - 2026-07-01

## Summary
- Scope: audit the current MVP for first-session clarity without increasing product complexity.
- Audience: players aged 10-14 on desktop and mobile.
- Rule for recommendations: only low-risk adjustments using existing HUD, remotes, config, prompts, and round-state systems.
- Baseline reviewed: `Lobby -> Starting -> InMatch -> Spectating` across `HUD.client.lua`, `ArenaState.lua`, `MatchService.server.lua`, `RespawnService.server.lua`, `ToolFactory.lua`, and `Config.lua`.

## What Is Already Working
- The game already has a coherent server-authoritative FTUE backbone: guided steps, late-join handling, round-format projection, base highlights, local feedback, and queue fairness.
- The route promise `Base -> Ilha do Meio -> Centro` is reinforced in both HUD and lobby boards.
- The project already avoids heavy systems and keeps most FTUE logic in config-backed text and state, which makes the next pass cheap to implement.

## Prioritized Backlog

### 1. Align the recommended purchase with the guided step
- Priority: `P1`
- Group: `Clareza de objetivo e onboarding`
- Symptom observed:
  The mission card advances from `blocos` to `ponte`, but the side recommendation immediately switches to sword after blocks are bought, even before the bridge is built.
- Code evidence:
  [src/Server/ArenaState.lua](</home/danie/projetos/cs-fan-zone/src/Server/ArenaState.lua:192>) and [src/Server/ArenaState.lua](</home/danie/projetos/cs-fan-zone/src/Server/ArenaState.lua:227>) compute the recommended starter and guided step independently.
- Impact on FTUE:
  The HUD can tell the player two different next actions at the same time. This is the highest-friction issue in the first minute.
- Minimal recommended adjustment:
  Gate sword recommendation until after `BuiltFirstBridge`, and gate pickaxe recommendation until after `CollectedEmerald` or after the bridge step is complete.
- Complexity:
  `muito baixa`

### 2. Stop low-value messages from overwriting critical messages
- Priority: `P1`
- Group: `Leitura de HUD, prompts e feedback local`
- Symptom observed:
  The client uses a single announcement lane for round start, first iron, purchase feedback, respawn, core attack, and core destruction.
- Code evidence:
  [src/Client/HUD.client.lua](</home/danie/projetos/cs-fan-zone/src/Client/HUD.client.lua:401>) uses one `announcementToken`, and all remote feedback paths call the same `showAnnouncement` function in [src/Client/HUD.client.lua](</home/danie/projetos/cs-fan-zone/src/Client/HUD.client.lua:720>).
- Impact on FTUE:
  Important warnings can disappear under less important tips, especially right after spawn and during the first combat exchange.
- Minimal recommended adjustment:
  Add a tiny priority gate inside `showAnnouncement` or suppress low-priority hints while a danger/warning message is active.
- Complexity:
  `baixa`

### 3. Make unaffordable shop clicks explain what is missing
- Priority: `P1`
- Group: `Leitura de HUD, prompts e feedback local`
- Symptom observed:
  When the player clicks an unaffordable item, the client only pulses red and plays an error sound. It does not explain which resource is missing because the request never reaches the server.
- Code evidence:
  [src/Client/HUD.client.lua](</home/danie/projetos/cs-fan-zone/src/Client/HUD.client.lua:536>) returns early on unaffordable items with no text feedback.
- Impact on FTUE:
  The player learns that the action failed, but not what to do next. This is especially costly in the first 25 seconds.
- Minimal recommended adjustment:
  Reuse the existing announcement lane to show `Faltam X Ferro/Ouro/Esmeralda` before returning.
- Complexity:
  `muito baixa`

### 4. Increase the spawn-protection window to match player perception
- Priority: `P1`
- Group: `Fricções evitáveis de combate/respawn/shop`
- Symptom observed:
  Respawn protection exists, but it lasts only `1` second.
- Code evidence:
  [src/Shared/Config.lua](</home/danie/projetos/cs-fan-zone/src/Shared/Config.lua:258>) sets `SpawnProtectionSeconds = 1`, and the protection is applied on character spawn in [src/Server/RespawnService.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/RespawnService.server.lua:94>).
- Impact on FTUE:
  New players can still feel instantly deleted near base, even though the system technically protects them.
- Minimal recommended adjustment:
  Raise the value to `2` or `2.5` seconds and keep combat-tool blocking as-is.
- Complexity:
  `muito baixa`

### 5. Persist the respawn countdown instead of showing it only once
- Priority: `P2`
- Group: `Fricções evitáveis de combate/respawn/shop`
- Symptom observed:
  When a player dies with the totem still alive, the countdown is sent once as a transient announcement and then disappears.
- Code evidence:
  [src/Server/RespawnService.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/RespawnService.server.lua:29>) sends `RespawnIn`, but the client only renders it as a temporary announcement in [src/Client/HUD.client.lua](</home/danie/projetos/cs-fan-zone/src/Client/HUD.client.lua:706>).
- Impact on FTUE:
  The player understands they will return, but not when. That creates avoidable confusion in the first death loop.
- Minimal recommended adjustment:
  Mirror the remaining respawn time into the left panel or help ribbon while the player is waiting.
- Complexity:
  `baixa`

### 6. Tighten countdown copy around the first practical action
- Priority: `P2`
- Group: `Clareza de objetivo e onboarding`
- Symptom observed:
  The countdown card explains only automatic base assignment, while the actionable instruction `pegue ferro` arrives later through other UI elements.
- Code evidence:
  [src/Shared/Config.lua](</home/danie/projetos/cs-fan-zone/src/Shared/Config.lua:346>) sets `StartingText`, and the round-start announcement is generic in [src/Server/MatchService.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/MatchService.server.lua:76>).
- Impact on FTUE:
  The transition into the match is readable, but not as directive as it could be for younger players.
- Minimal recommended adjustment:
  Change countdown and round-start copy to explicitly say `nasceu -> pegue ferro -> abra a loja`.
- Complexity:
  `muito baixa`

### 7. Make overflow-lobby messaging explain priority explicitly
- Priority: `P2`
- Group: `Clareza de objetivo e onboarding`
- Symptom observed:
  Players left out of a `3-player` or `5-player` queue receive a generic wait message, even though queue priority already exists in code.
- Code evidence:
  The overflow notice is sent in [src/Server/MatchService.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/MatchService.server.lua:91>) with copy from [src/Shared/Config.lua](</home/danie/projetos/cs-fan-zone/src/Shared/Config.lua:364>). Queue fairness is already implemented in [src/Server/ArenaState.lua](</home/danie/projetos/cs-fan-zone/src/Server/ArenaState.lua:640>).
- Impact on FTUE:
  The player is protected by the queue system but may still feel skipped or bugged.
- Minimal recommended adjustment:
  Update the message to explicitly state that the player has priority in the next round.
- Complexity:
  `muito baixa`

### 8. Replace `ON/OFF` standings language with child-readable Portuguese
- Priority: `P3`
- Group: `Leitura de HUD, prompts e feedback local`
- Symptom observed:
  Standings use `totem ON/OFF`, which is shorter but colder and less readable than the rest of the Portuguese UI.
- Code evidence:
  [src/Client/HUD.client.lua](</home/danie/projetos/cs-fan-zone/src/Client/HUD.client.lua:629>) formats standings rows with `ON/OFF`.
- Impact on FTUE:
  Low severity, but it weakens readability and tone consistency.
- Minimal recommended adjustment:
  Use `ativo/quebrado` or `protegido/aberto`.
- Complexity:
  `muito baixa`

### 9. Rework the lobby onboarding card for safer mobile fit
- Priority: `P3`
- Group: `Clareza de objetivo e onboarding`
- Symptom observed:
  The onboarding card uses fixed offsets and tight vertical spacing for title, subtitle, queue, format, and four objectives.
- Code evidence:
  [src/Client/HUD.client.lua](</home/danie/projetos/cs-fan-zone/src/Client/HUD.client.lua:197>) to [src/Client/HUD.client.lua](</home/danie/projetos/cs-fan-zone/src/Client/HUD.client.lua:220>) place the card content manually with no vertical layout container.
- Impact on FTUE:
  The desktop view is likely acceptable, but smaller screens have a higher risk of clipping or crowded reading during the first 10 seconds.
- Minimal recommended adjustment:
  Switch the card body to `UIListLayout` plus `UIPadding`, or increase card height and shorten one line of copy.
- Complexity:
  `baixa`

### 10. Rebalance starter economy copy, not the economy itself
- Priority: `P3`
- Group: `Ritmo dos primeiros 60 segundos`
- Symptom observed:
  The current economy is close to the intended first-minute targets, but the wording around it does not always explain why iron comes first and gold comes second.
- Code evidence:
  Base iron and gold pacing in [src/Shared/Config.lua](</home/danie/projetos/cs-fan-zone/src/Shared/Config.lua:171>) and [src/Shared/Config.lua](</home/danie/projetos/cs-fan-zone/src/Shared/Config.lua:177>) already support a usable first minute.
- Impact on FTUE:
  The numbers are acceptable, so changing costs first would add risk without solving the main clarity issue.
- Minimal recommended adjustment:
  Keep costs unchanged for now; improve copy and local hints first, then only tune economy if playtests still show missed timing targets.
- Complexity:
  `muito baixa`

## Recommended Implementation Order
1. Align starter recommendation with guided-step progression.
2. Add message priority so critical feedback survives.
3. Add explicit missing-resource feedback on unaffordable shop clicks.
4. Raise spawn protection to a more perceptible value.
5. Persist respawn countdown in a visible HUD slot.
6. Improve countdown and overflow copy.
7. Polish standings language and lobby-card layout.

## Assumptions
- No new remotes are required for the first four items.
- No new persistent systems, matchmaking logic, monetization, or map rework should be introduced during this pass.
- Existing build and playtest flow remains the validation path after implementation:
  `~/.rokit/bin/rojo build -o build.rbxlx`
  `~/.rokit/bin/rojo serve`
