# AI_PERFORMANCE_BUDGET

TARGET: public alpha that remains playable on common Roblox mobile devices

## WORLD_BUDGET
- prefer anchored static Parts
- keep decorative props simple and reusable
- avoid unnecessary MeshPart or Terrain in this phase
- cap permanent ParticleEmitters to purposeful generator/core/center effects
- cap always-on BillboardGui to gameplay-critical labels only
- avoid server per-frame visual loops
- keep collision simple on decorative props

## UI_BUDGET
- one main ScreenGui
- avoid rebuilding full HUD every frame
- update UI only from remote events or state changes
- avoid excessive TextScaled on dense panels
- use layout objects instead of manual repositioning where practical

## VFX_AUDIO_BUDGET
- client-side cosmetic effects when possible
- short-lived flashes/pulses only
- placeholder sound IDs remain `rbxassetid://0` until licensed assets are selected
- every external asset must be registered in `docs/asset-register.md`

## VALIDATION
- `~/.rokit/bin/rojo build -o build.rbxlx`
- `~/.rokit/bin/rojo serve`
- Studio Play desktop for 5 minutes with zero red errors
- Studio mobile viewport check for HUD clipping
- screenshot checklist in `docs/VISUAL_QA.md`
