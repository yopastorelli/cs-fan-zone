# AI_HANDOFF

BRANCH: feat/premium-visual-pass
MODE: arena competitiva adaptativa
ROUND_FORMAT: 2-3 jogadores elegiveis resolvem 1v1; 4+ jogadores elegiveis retomam duplas completas, sem time parcial
CURRENT_TARGET: child-first clarity pass for ages 10-14 + guided first minute + solo preview
MAP: seis bases por bioma em portugues; bases inativas entram como reserva visual; rotas visuais base -> Ilha do Meio -> Centro sem pontes permanentes
VISUAL_BASELINE: mobile fraco, tier `Low`, ShadowMap, brilho premium restrito
ROSTER: nenhum nome real; times usam apenas labels ficcionais por bioma
PLAYER_PHASES: Lobby, InMatch, Spectating
MATCH_STATES: Waiting, Starting, Active, SuddenDeath, Ended
SERVER_AUTHORITY: time, formato de rodada, recursos, compras, upgrades, coleta, colocacao, totem, respawn, vitoria, empate
CLIENT_CONTRACTS: MatchStateUpdated, TeamStateUpdated, InventoryUpdated, AnnouncementPushed, FeedbackPushed, ShopOpened, TelemetryRequested
ACTIVE_RULES: late join fica no lobby; loadout nao persiste apos morte; upgrades de time persistem ate o fim da rodada; prompts e geradores de base reserva ficam inativos
STARTER_FLOW_SOURCE: custos, display names e recomendacoes starter derivam de `Config.Shop.Items`; sem hardcode residual permitido
ROUND_RUNTIME_GUARD: `ArenaState.RoundToken` invalida callbacks atrasados de SuddenDeath e respawn entre rodadas
RUNTIME_RESILIENCE: `CoreService`, `ShopService`, `GeneratorService` e `ObjectiveService` reconectam descendants adicionados apos rebuild/sync
SPAWN_PROTECTION: `Config.Combat.SpawnProtectionSeconds` protege respawn contra dano competitivo imediato; ataque com espada/picareta tambem fica bloqueado nessa janela
LOBBY_WORLD_STATE: `QueueStatusSign`, `TacticalBoard` e `MiniMapBoard` refletem estado real da fila/rodada por `ArenaState.BroadcastMatchState`
FTUE_FUNNEL: ftue_spawn_lobby -> ftue_collect_iron -> ftue_open_shop -> ftue_buy_blocks -> ftue_build_first_bridge -> ftue_reach_middle -> ftue_collect_emerald
VISUAL_MODULES: src/Shared/VisualKit.lua, src/Server/WorldBuilder.lua, src/Server/EnvironmentService.server.lua
UX_MODULES: src/Client/HUD.client.lua, src/Server/ArenaState.lua, src/Server/MatchService.server.lua
AUDIENCE: 10 a 14 anos; onboarding deve ensinar a primeira partida sem tutor externo
KNOWN_RISKS:
- smoke manual no Studio ainda e obrigatorio para validar clareza real
- highlights/context hints precisam ser observados com 1 jogador, 1v1 ativo e duplas ativas
- bases reserva devem ser revisadas visualmente no Play para nao parecer bug
- preview de base no lobby precisa ser checado para nao poluir o primeiro frame
- spawn protection precisa ser validada em troca real de PvP perto da base
CURRENT_LIMITS:
- sem persistencia
- sem matchmaking cross-server
- sem monetizacao
- sem bots
- sem teste headless real de Studio
- telemetria depende de validacao no dashboard/Studio analytics, nao em smoke local
- sem texturas externas de Minecraft; look voxel vem de massa, material e formas originais
- tier `Standard` e comparativo por config; nao existe menu in-game para trocar qualidade
NEXT_AUDIT_FOCUS:
- validar `Low` vs `Standard`
- validar se `ShadowMap` entrega profundidade suficiente no baseline
- validar spawn do lobby olhando para o centro
- validar preview de base no lobby
- validar leitura de saidas de rota sem pontes permanentes
- validar leitura de `6 Ilhas do Meio + 3 Centro` para esmeraldas
- validar passo guiado `ferro -> loja -> blocos -> Ilha do Meio -> esmeralda`
- validar 1/2/3 jogadores
- validar late join
- validar mobile viewport
FTUE_AUDIT_2026_07_01:
- doc fonte: `docs/FTUE_AUDIT_2026-07-01.md`
- P1: alinhar recomendacao starter com passo guiado
- P1: impedir que anuncios fracos apaguem alertas criticos
- P1: explicar recurso faltante ao clicar item indisponivel
- P1: aumentar `SpawnProtectionSeconds` para janela perceptivel
- P2: persistir countdown de respawn na HUD
- P2: explicitar `prioridade na proxima rodada` para overflow lobby
RUNTIME_INFRA_AUDIT_2026_07_01:
- doc fonte: `docs/RUNTIME_INFRA_AUDIT_2026-07-01.md`
- P1: consolidar ownership de resolucao de vitoria/empate
- P1: unificar ownership de lifecycle de jogador
- P1: remover ou classificar services-placeholder vazios
- P2: ampliar smoke para regressao de fronteira entre services
- P2: limpar ou documentar estado de registro em `WorldRuntime`
NEXT_TEST: abrir Studio, conectar Rojo, rodar Play, seguir tests/manual-smoke.md e docs/checklists/release.md
