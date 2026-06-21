# Manual smoke tests

## WSL

```bash
cd /home/danie/projetos/cs-fan-zone
git status
rokit install
~/.rokit/bin/rojo --version
~/.rokit/bin/rojo build -o build.rbxlx
~/.rokit/bin/rojo serve
curl -fsS http://127.0.0.1:34872/ >/dev/null && echo OK
```

## Roblox Studio

1. Conectar o plugin do Rojo ao `rojo serve`.
2. Confirmar que `Workspace.CSFanZone` contem `Hub`, `Arena`, `Parkour`, `Shop`, `Leaderboard` e `Portals`.
3. Verificar spawn no hub.
4. Coletar moedas na arena e confirmar incremento em `leaderstats.Coins`.
5. Aguardar o fim da rodada e confirmar atualizacao de `Wins`.
6. Abrir a loja, tentar comprar sem saldo e depois com saldo suficiente.
7. Equipar um cosmetico e validar o atributo `EquippedCosmetic`.
8. Testar os botoes e portais de teleporte para `Hub`, `Arena`, `Parkour` e `Shop`.
9. Confirmar que o HUD mostra moedas, vitorias, cronometro e mensagens de rodada sem erros no cliente.
