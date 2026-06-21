# AI_HANDOFF

BRANCH: feat/premium-visual-pass
MODE: arena competitiva adaptativa
ROUND_FORMAT: 2..6 duplas conforme populacao; sem time parcial
CURRENT_TARGET: audit hardening + IA-first docs + UX clarity
MAP: seis bases por bioma em portugues; bases inativas entram como reserva visual
ROSTER: Bern+Caduxinn, Chip+Feuripe, Fixz+Ligonz, Mendrake+Muca, Nait+Pedrux, Geleia+Tonigon
PLAYER_PHASES: Lobby, InMatch, Spectating
MATCH_STATES: Waiting, Starting, Active, SuddenDeath, Ended
SERVER_AUTHORITY: time, formato adaptativo, recursos, compras, upgrades, coleta, colocacao, nucleo, respawn, vitoria, empate
CLIENT_CONTRACTS: MatchStateUpdated, TeamStateUpdated, InventoryUpdated, AnnouncementPushed, FeedbackPushed, ShopOpened
ACTIVE_RULES: late join fica no lobby; loadout nao persiste apos morte; upgrades de time persistem ate o fim da rodada; prompts e geradores de base reserva ficam inativos
VISUAL_MODULES: src/Shared/VisualKit.lua, src/Server/WorldBuilder.lua, src/Server/EnvironmentService.server.lua
UX_MODULES: src/Client/HUD.client.lua, src/Server/ArenaState.lua, src/Server/MatchService.server.lua
KNOWN_RISKS:
- smoke manual no Studio ainda e obrigatorio para validar clareza real
- highlights/context hints precisam ser observados com 1 jogador e com rodada cheia
- bases reserva devem ser revisadas visualmente no Play para nao parecer bug
CURRENT_LIMITS:
- sem persistencia
- sem matchmaking cross-server
- sem monetizacao
- sem bots
- sem teste headless real de Studio
NEXT_AUDIT_FOCUS:
- validar 1/4/6/8/10/12 jogadores
- validar late join
- validar zero spam de anuncios locais
- validar mobile viewport
NEXT_TEST: abrir Studio, conectar Rojo, rodar Play, seguir tests/manual-smoke.md e docs/checklists/release.md
