# AI_MANUAL_SMOKE_SPEC

## WSL
1. `cd /home/danie/projetos/cs-fan-zone`
2. `~/.rokit/bin/rojo build -o build.rbxlx`
3. `~/.rokit/bin/rojo serve`
4. `curl -fsS http://127.0.0.1:34872/ >/dev/null && echo OK`

## STUDIO
1. `Workspace.CSFanZone` existe
2. jogador sozinho nasce no `LobbySpawn`, no chao, sem plataforma aerea inicial
3. em ate 10s o HUD deixa claro objetivo, fila minima e proximo passo
4. o lobby mostra vista clara da arena, centro e 6 bases: Planicie, Deserto, Taiga, Selva, Neve, Cogumelos
5. ao iniciar contagem, aparece countdown central e aviso de dupla automatica
6. em partida, HUD mostra estado, timer, recursos e placar de duplas
7. geradores soltam pickups de recurso com labels legiveis
8. loja abre por prompt e compra funciona
9. upgrades abrem por prompt e aplicam na dupla
10. espada causa dano em inimigo
11. picareta danifica nucleo inimigo
12. la coloca blocos
13. jogador respawna se o proprio nucleo estiver vivo
14. jogador vira espectador se o nucleo do proprio time estiver destruido
15. se todas as duplas morrerem apos `SuddenDeath`, a rodada encerra como empate
16. ultima dupla viva vence
17. nao e possivel comprar, melhorar ou colocar bloco no lobby/spectator

## VISUAL_QA
1. screenshot inicial do lobby nao parece vazio
2. cada bioma e reconhecivel por silhueta/cor sem ler a placa
3. centro parece objetivo premium por luz, altura e VFX
4. loja e upgrades parecem stands diferentes, nao cubos genericos
5. nucleo fica destacado em pedestal com aura
6. HUD nao corta texto em viewport desktop
7. HUD nao corta texto em viewport mobile
8. loja mostra categorias e estado visual de compra possivel/recusada
9. coleta de recurso gera feedback visual na HUD
10. hit/destruicao de nucleo gera anuncio claro
