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
4. com poucos jogadores, o HUD deixa claro o formato adaptativo previsto da proxima rodada
5. card de ajuda no lobby pode ser fechado e reaberto por botao `Ajuda`
6. late join durante rodada ativa fica no lobby e recebe explicacao clara
7. com `4 jogadores`, a rodada ativa `2 duplas`
8. com `6/8/10 jogadores`, a rodada ativa o numero correspondente de duplas
9. com `12 jogadores`, as `6 duplas` entram normalmente
10. bases reserva ficam visualmente fora da rodada e nao parecem bug
11. geradores e prompts de bases reserva nao interferem
12. o lobby mostra vista clara da arena, centro e 6 bases: Planicie, Deserto, Taiga, Selva, Neve, Cogumelos
13. no primeiro frame nao existem labels gigantes sobrepostas de loja, upgrades ou rota
14. ao iniciar contagem, aparece countdown central e aviso de dupla automatica
15. em partida, HUD mostra estado, timer, recursos, formato da rodada e placar das duplas ativas
16. ao nascer na base, aparecem highlights temporarios para nucleo, loja, upgrades, ferro e ouro
17. geradores soltam pickups de recurso com labels legiveis
18. loja abre por prompt e compra funciona
19. loja destaca compras iniciais de blocos/espada e papel da picareta
20. upgrades abrem por prompt e aplicam na dupla
21. compras e upgrades locais nao geram spam global desnecessario
22. espada causa dano em inimigo
23. picareta danifica nucleo inimigo
24. la coloca blocos
25. jogador respawna se o proprio nucleo estiver vivo
26. jogador vira espectador se o nucleo do proprio time estiver destruido
27. se todas as duplas morrerem apos `SuddenDeath`, a rodada encerra como empate
28. ultima dupla viva vence
29. nao e possivel comprar, melhorar ou colocar bloco no lobby/spectator

## VISUAL_QA
1. screenshot inicial do lobby nao parece vazio
2. screenshot inicial do lobby nao parece poluido por texto flutuante
3. cada bioma e reconhecivel por silhueta/cor sem ler a placa
4. centro parece objetivo premium por luz, altura e VFX
5. loja e upgrades parecem stands diferentes, nao cubos genericos, e seus nomes aparecem integrados ao stand
6. nucleo fica destacado em pedestal com aura
7. superficies claras nao estouram em branco a ponto de esconder forma/material
8. HUD nao corta texto em viewport desktop
9. HUD nao corta texto em viewport mobile
10. loja mostra categorias e estado visual de compra possivel/recusada
11. coleta de recurso gera feedback visual na HUD
12. hit/destruicao de nucleo gera anuncio claro
