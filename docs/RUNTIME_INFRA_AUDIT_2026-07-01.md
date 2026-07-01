# Runtime / Infra Audit - 2026-07-01

## Summary
- Scope: runtime, world bootstrap, infra wiring, service boundaries, smoke coverage, and observability.
- Out of scope: first-minute FTUE and HUD polish already covered in `docs/FTUE_AUDIT_2026-07-01.md`.
- Rule for recommendations: no new gameplay systems, no new network protocol, no structural map rewrite, and no increase in product complexity.

## Validation Baseline
- `~/.rokit/bin/rojo build -o build.rbxlx`: passed on `2026-07-01`.
- `timeout 5 ~/.rokit/bin/rojo serve`: command was valid, but the port was already bound in the local environment, so the run ended with `Address already in use`.
- This means build integrity was confirmed; Studio/runtime smoke still remains the source of truth for behavior.

## Prioritized Backlog

### 1. Consolidate win/draw resolution ownership
- Priority: `P1`
- Group: `Robustez de runtime e wiring`
- Symptom observed:
  Match state progression is driven by one global loop, while victory/draw resolution is driven by a separate polling loop.
- Code evidence:
  [src/Server/MatchService.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/MatchService.server.lua:124>) and [src/Server/CombatResolutionService.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/CombatResolutionService.server.lua:8>).
- Impact:
  Round authority is split across two always-on loops. That is still workable for MVP, but it lowers predictability and makes timing bugs harder to reason about.
- Minimal recommended adjustment:
  Move win/draw checking into the existing match-state authority path or a single server tick owner. Keep the logic, reduce ownership fragmentation.
- Complexity:
  `baixa`

### 2. Unify player lifecycle ownership
- Priority: `P1`
- Group: `Qualidade de serviços e responsabilidades`
- Symptom observed:
  Player initialization and cleanup are spread across `TeamService`, `Leaderstats`, `RespawnService`, `TelemetryService`, and `ArenaState`.
- Code evidence:
  [src/Server/TeamService.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/TeamService.server.lua:5>), [src/Server/Leaderstats.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/Leaderstats.server.lua:27>), [src/Server/RespawnService.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/RespawnService.server.lua:105>), [src/Server/TelemetryService.lua](</home/danie/projetos/cs-fan-zone/src/Server/TelemetryService.lua:90>), and [src/Server/ArenaState.lua](</home/danie/projetos/cs-fan-zone/src/Server/ArenaState.lua:1471>).
- Impact:
  The project has multiple valid entrypoints for the same lifecycle. That increases the chance of partial cleanup, duplicated defaults, or future regressions when one service changes and another does not.
- Minimal recommended adjustment:
  Define one explicit lifecycle owner for player state bootstrap and teardown. Other services should subscribe only for their local concerns.
- Complexity:
  `baixa`

### 3. Remove or formally classify empty services
- Priority: `P1`
- Group: `Higiene de código e débito aceitável vs. não aceitável`
- Symptom observed:
  `ObjectiveService.server.lua` and `CoreService.server.lua` only wait for `Workspace.CSFanZone` and do nothing else.
- Code evidence:
  [src/Server/ObjectiveService.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/ObjectiveService.server.lua:1>) and [src/Server/CoreService.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/CoreService.server.lua:1>).
- Impact:
  These files look like active services but behave like placeholders. That creates false surface area and makes maintenance harder.
- Minimal recommended adjustment:
  Either delete them and move ownership to the real service, or convert them into documented placeholders with a short header explaining why they still exist.
- Complexity:
  `muito baixa`

### 4. Make runtime registration tables resilient to rebuilt instances
- Priority: `P2`
- Group: `Robustez de runtime e wiring`
- Symptom observed:
  `WorldRuntime` keeps prompt and trigger registration state in tables keyed by instance, but there is no explicit cleanup path when rebuilt objects are destroyed.
- Code evidence:
  [src/Server/WorldRuntime.lua](</home/danie/projetos/cs-fan-zone/src/Server/WorldRuntime.lua:14>).
- Impact:
  This is probably fine for the current single-bootstrap flow, but it becomes fragile if rebuild/sync/rebind behavior grows. The failure mode is not immediate gameplay breakage, but stale registration state and harder debugging.
- Minimal recommended adjustment:
  Add lightweight cleanup on instance destruction or rebuild entrypoints, without introducing a full resource manager.
- Complexity:
  `baixa`

### 5. Document `Touched`-based milestone triggers as acceptable but narrow
- Priority: `P2`
- Group: `Performance e loops recorrentes`
- Symptom observed:
  Resource pickups and middle-island milestones rely on `Touched` listeners plus manual debounce.
- Code evidence:
  [src/Server/GeneratorService.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/GeneratorService.server.lua:108>) and [src/Server/WorldRuntime.lua](</home/danie/projetos/cs-fan-zone/src/Server/WorldRuntime.lua:50>).
- Impact:
  For the current scale this is acceptable, but `Touched` can be noisy and can hide edge cases in crowded matches or rebuild-heavy sessions.
- Minimal recommended adjustment:
  Keep the current approach for MVP, but add smoke/test notes and keep all future `Touched` usages behind explicit debounce/phase guards like these.
- Complexity:
  `muito baixa`

### 6. Expand smoke coverage for service-boundary regressions
- Priority: `P2`
- Group: `Cobertura de smoke/testes e observabilidade`
- Symptom observed:
  `SmokeTests.server.lua` already covers world shape, config, budgets, and some API exposure, but not placeholder services, lifecycle ownership, or telemetry ingress policy.
- Code evidence:
  [src/Server/SmokeTests.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/SmokeTests.server.lua:1>).
- Impact:
  The project validates gameplay configuration well, but not the maintenance boundaries most likely to regress when services are reorganized.
- Minimal recommended adjustment:
  Add assertions for:
  `TelemetryRequested` existence and allowed-event gate,
  placeholder-service policy,
  and one explicit check that player lifecycle state is initialized consistently.
- Complexity:
  `baixa`

### 7. Reduce silent-failure surface in telemetry
- Priority: `P3`
- Group: `Cobertura de smoke/testes e observabilidade`
- Symptom observed:
  Telemetry intentionally swallows analytics API differences via chained `pcall`, but it exposes no local debug signal when all variants fail.
- Code evidence:
  [src/Server/TelemetryService.lua](</home/danie/projetos/cs-fan-zone/src/Server/TelemetryService.lua:20>).
- Impact:
  Safe for production, but weak for diagnosis. Analytics can silently stop providing value without giving maintainers a clear local clue.
- Minimal recommended adjustment:
  Keep production-safe fallback, but add a lightweight dev-only warning path or checklist note for manual telemetry verification.
- Complexity:
  `muito baixa`

### 8. Treat `WorldBootstrap` as a high-value maintenance hotspot
- Priority: `P3`
- Group: `Qualidade de serviços e responsabilidades`
- Symptom observed:
  `WorldBootstrap.server.lua` centralizes map construction, root clearing, registration, signage, preview content, and safe-zone tagging in one very large script.
- Code evidence:
  [src/Server/WorldBootstrap.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/WorldBootstrap.server.lua:1>).
- Impact:
  The current approach is still pragmatic for MVP, but it is the biggest single-point maintenance hotspot in the codebase.
- Minimal recommended adjustment:
  Do not split it aggressively now; instead, annotate it as the primary candidate for future extraction by subsystem (`lobby`, `bases`, `center`, `runtime registration`) when maintenance pain becomes real.
- Complexity:
  `muito baixa`

### 9. Keep `Remotes` side effects explicit
- Priority: `P3`
- Group: `Robustez de runtime e wiring`
- Symptom observed:
  Several services call `Remotes.GetAll()`, which creates server remotes as a side effect.
- Code evidence:
  [src/Shared/Remotes.lua](</home/danie/projetos/cs-fan-zone/src/Shared/Remotes.lua:47>), [src/Server/WorldBootstrap.server.lua](</home/danie/projetos/cs-fan-zone/src/Server/WorldBootstrap.server.lua:14>), and [src/Server/TelemetryService.lua](</home/danie/projetos/cs-fan-zone/src/Server/TelemetryService.lua:95>).
- Impact:
  This works, but remote creation is no longer obviously owned by one bootstrap path.
- Minimal recommended adjustment:
  Keep current implementation, but treat `WorldBootstrap` or one central server initializer as the canonical place that guarantees remote creation.
- Complexity:
  `muito baixa`

## Immediate Execution Order
1. Consolidate match-resolution ownership.
2. Unify player lifecycle ownership.
3. Remove or formally classify empty services.
4. Expand smoke coverage for service-boundary regressions.
5. Add light cleanup/documentation around `WorldRuntime` registration tables.

## Recommended Next-Round Best Practices
- Keep gameplay loops state-gated and avoid introducing new polling owners.
- Any new `Touched` gameplay trigger must include debounce plus phase validation.
- Any new service must either own real behavior or be explicitly labeled as a placeholder.
- Treat smoke tests as infra contracts, not only gameplay/config validation.

## Acceptable MVP Debt
- `WorldBootstrap.server.lua` remaining large is acceptable for now.
- Per-generator loops in `GeneratorService.server.lua` are acceptable because they are gameplay-bound and already scoped.
- Telemetry’s defensive `pcall` strategy is acceptable if manual verification remains part of release flow.

## Assumptions
- The audit intentionally does not revisit FTUE/HUD recommendations.
- The `rojo serve` port conflict observed during validation came from local environment state, not from evidence of a project runtime defect.
- The next implementation round should prefer consolidation and clearer ownership over abstraction or new architecture.
