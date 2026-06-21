# AI_MANUAL_SMOKE_SPEC

## WSL
1. `cd /home/danie/projetos/cs-fan-zone`
2. `~/.rokit/bin/rojo build -o build.rbxlx`
3. `~/.rokit/bin/rojo serve`
4. `curl -fsS http://127.0.0.1:34872/ >/dev/null && echo OK`

## STUDIO
1. `Workspace.CSFanZone` existe
2. existem 6 bases: Planicie, Deserto, Taiga, Selva, Neve, Cogumelos
3. HUD mostra estado, timer, recursos e placar de duplas
4. geradores soltam pickups de recurso
5. loja abre por prompt e compra funciona
6. upgrades abrem por prompt e aplicam na dupla
7. espada causa dano em inimigo
8. picareta danifica nucleo inimigo
9. la coloca blocos
10. jogador respawna se o proprio nucleo estiver vivo
11. jogador vira espectador se o nucleo do proprio time estiver destruido
12. ultima dupla viva vence
