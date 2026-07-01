# AI_MANUAL_SMOKE_SPEC

## WSL
1. `cd /home/danie/projetos/cs-fan-zone`
2. `~/.rokit/bin/rojo build -o build.rbxlx`
3. `~/.rokit/bin/rojo serve`
4. `curl -fsS http://127.0.0.1:34872/ >/dev/null && echo OK`
5. validar visual default em tier `Low`

## STUDIO
1. `Workspace.CSFanZone` existe
2. jogador sozinho nasce no `LobbySpawn`, no chao, sem plataforma aerea inicial
3. em ate 10s o HUD deixa claro objetivo, fila minima e proximo passo
4. com poucos jogadores, o HUD deixa claro que faltam jogadores para iniciar
5. no lobby, existe `Exemplo da Base` com totem, ferro, ouro, loja, upgrades e saidas
6. card de ajuda no lobby pode ser fechado e reaberto por botao `Ajuda`
7. com `2 jogadores`, a rodada inicia como `1v1` com Planicie e Selva ativas
8. com `3 jogadores`, apenas 2 entram na rodada e o terceiro fica no lobby com explicacao clara
9. na rodada seguinte com `3 jogadores`, quem ficou de fora tem prioridade para jogar
10. com `4 jogadores`, a rodada inicia como `2 duplas`, com 2 jogadores por time
11. com `5 jogadores`, 4 entram como `2 duplas` e o quinto fica no lobby com prioridade para a proxima rodada
12. com `6 jogadores`, a rodada inicia como `3 duplas`
13. late join durante rodada ativa fica no lobby e recebe explicacao clara
14. bases reserva ficam visualmente fora da rodada e nao parecem bug
15. geradores, prompts e totens de bases reserva nao interferem nem recebem dano
16. o lobby mostra vista clara da arena, centro e 6 bases: Planicie, Deserto, Taiga, Selva, Neve, Cogumelos
17. no primeiro frame o jogador olha para a arena; nao ve o verso das placas principais
18. no primeiro frame nao existem labels gigantes sobrepostas de loja, upgrades ou rota
19. as saidas de rota deixam claro o trajeto `base -> Ilha do Meio -> Centro`
20. o corredor Planicie/Selva fica mais curto e destacado que as rotas reserva
21. nao existe ponte permanente completa ligando base a Ilha do Meio ou Centro
22. ao iniciar contagem, aparece countdown central e aviso de base automatica
23. em partida, HUD mostra estado, timer, recursos, formato da rodada e placar dos times ativos
24. em partida, o cartao central mostra a proxima missao com `Passo X/6`
25. ao nascer na base, aparecem highlights temporarios por cerca de `10s` para totem, loja, upgrades, ferro, ouro e saida da base
26. o passo guiado avanca em ordem real: `ferro -> loja -> blocos -> ponte -> esmeralda`
27. o passo de blocos fala `La x20`, nao `La x16`
28. `Ajuda` reabre o cartao contextual sem travar a HUD
29. anuncios rapidos nao apagam anuncios mais recentes fora de ordem
30. o ritmo inicial bate metas aproximadas: primeiro ferro em `5-10s`, primeira compra em `<=25s`, primeira ponte em `<=45s`
31. geradores soltam pickups de recurso com labels legiveis
32. Ilhas do Meio e Centro deixam claro onde ficam as esmeraldas
33. a leitura premium de esmeralda bate com `6 Ilhas do Meio + 3 Centro`
34. loja abre por prompt e compra funciona
35. loja destaca o item `AGORA` corretamente para a fase do jogador
36. upgrades abrem por prompt e aplicam no time
37. compras e upgrades locais nao geram spam global desnecessario
38. espada causa dano em inimigo
39. picareta danifica somente o totem inimigo ativo
40. hit e destruicao de totem geram feedback visual e som curto
41. coleta, compra, erro, upgrade e vitoria geram feedback sonoro curto
42. da para colocar blocos
43. primeira ponte gera feedback claro
44. primeira chegada a Ilha do Meio gera feedback claro
45. jogador respawna se o proprio totem estiver vivo
46. jogador vira espectador se o proprio totem estiver destruido
47. jogador renascido perto da base nao toma dano imediato durante a janela curta de spawn protection
48. jogador em spawn protection nao consegue abusar espada/picareta antes da janela acabar
49. se rebuild/sync acontecer, prompts, geradores e triggers do meio continuam funcionando sem depender de labels ou wiring duplicado
50. `SuddenDeath` antigo nao pode disparar na rodada seguinte se a rodada atual ja reiniciou
51. `SuddenDeath` destroi apenas totens dos times ativos
52. respawn atrasado de uma rodada anterior nao pode trazer jogador de volta na fase errada
53. se todos os times morrerem apos `SuddenDeath`, a rodada encerra como empate
54. ultimo time vivo vence
55. nao e possivel comprar, melhorar ou colocar bloco no lobby/spectator

## VISUAL_QA
1. baseline `Low` usa leitura forte de massa e nao depende de glow
2. comparar `Low` vs `Standard` em lobby, Neve e Centro
3. screenshot inicial do lobby nao parece vazio
4. screenshot inicial do lobby nao parece poluido por texto flutuante
5. cada bioma e reconhecivel por silhueta/cor sem ler a placa
6. o visual parece blocky/voxel e nao um prototipo liso com neon
7. centro parece objetivo premium por luz, altura e shrine de esmeralda
8. loja e upgrades parecem stands diferentes, nao cubos genericos, e seus nomes aparecem integrados ao stand
9. totem fica destacado e legivel em pedestal proprio
10. superficies claras nao estouram em branco a ponto de esconder forma/material
11. HUD nao corta texto em viewport desktop
12. HUD nao corta texto em viewport mobile
13. loja mostra categorias e estado visual de compra possivel/recusada
14. coleta de recurso gera feedback visual na HUD
15. coleta comum de recurso nao deve repintar perceptivelmente toda a HUD
16. hit/destruicao de totem gera anuncio claro
17. a arena parece survival/build chaos com leitura voxel clara e nao arena sci-fi pronta
18. placas do lobby refletem fila/estado real e nao ficam congeladas em texto estatico
