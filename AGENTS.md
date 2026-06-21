# CS Fan Zone

## Objective
Build a Roblox MVP about exploration and community nostalgia, with a short mission loop that is easy to understand and useful for teaching Luau basics.

## Required constraints
- Run project commands from WSL at `/home/danie/projetos/cs-fan-zone`.
- Use Rokit and Rojo for Roblox tooling.
- Keep important source code in `src/Client`, `src/Server`, and `src/Shared`.
- Do not use real names, official logos, voices, video frames, exact slogans, recognizable avatars, or third-party IP without explicit license.
- Use indirect, original references and fictional symbols.
- Do not add off-platform links, QR codes, Discord prompts, email requests, or personal-data collection.
- Register every external asset in `docs/asset-register.md`.
- Add required credits to `docs/ATTRIBUTIONS.md`.
- Prefer `Part`, `SurfaceGui`, `BillboardGui`, `ProximityPrompt`, built-in materials, and event-driven scripts.
- Avoid expensive per-frame loops unless gameplay requires them.

## Validation
- Run `~/.rokit/bin/rojo build -o build.rbxlx` after important changes.
- Run `~/.rokit/bin/rojo serve` before Studio playtests.
- Keep `tests/manual-smoke.md` current.
- Do not rewrite Git history unless explicitly requested.
