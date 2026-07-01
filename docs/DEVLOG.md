# AI_DEVLOG

## 2026-06-21
- Created Rojo/Rokit project bootstrap.
- Replaced the exploration loop with a competitive arena, now scoped to adaptive 1v1/duplas MVP.
- Added six biome bases in Portuguese: Planicie, Deserto, Taiga, Selva, Neve, Cogumelos.
- Added server-authoritative match flow, team assignment, generators, item shop, upgrades, cores, respawn, elimination, and victory resolution.
- Added procedural base-defense combat tools for sword, pickaxe, healing, and wool block placement.
- Added lobby-first onboarding, late-join lobby policy, spectator-only post-elimination flow, and alpha hardening for shop, upgrade, block placement, and draw resolution.
- Added premium visual pass foundation: VisualKit, WorldBuilder, environment lighting, richer biome bases, arena reveal lobby, premium center, responsive HUD, categorized shop, and cosmetic feedback remote.
- Replaced the public objective with biome totems, switched public route copy to `Ilha do Meio` and `Centro`, and tightened emerald readability to `6 + 3`.
- Added child-first guidance for ages 10-14: guided first-minute objectives, recommended starter purchases, lobby preview base, mini map board, and first bridge / first middle feedback.
- Preserved compliance gates for original, non-branded content only.

## 2026-07-01
- Added a dedicated FTUE audit backlog in `docs/FTUE_AUDIT_2026-07-01.md`.
- Prioritized low-complexity fixes over new systems: guided-step alignment, message priority, clearer shop denial feedback, and more perceptible spawn protection.
- Captured follow-up HUD/documentation targets for the next implementation pass in `docs/AI_HANDOFF.md`.
- Added a second independent audit focused on runtime, world bootstrap, infra wiring, placeholders, smoke coverage, and observability in `docs/RUNTIME_INFRA_AUDIT_2026-07-01.md`.
