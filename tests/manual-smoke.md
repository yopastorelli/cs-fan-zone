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
2. Confirmar que `Workspace.CSFanZone` contem `CentralPlaza`, `NostalgiaWall`, `ClipStage`, `MemeLounge` e `FinalCelebrationRoom`.
3. Verificar spawn na Praca Central.
4. Confirmar que a HUD mostra objetivo, `Memorias: 0/12` e `POIs: 0/3`.
5. Encontrar o primeiro coletavel em menos de 60 segundos.
6. Coletar 12 memorias unicas e confirmar incremento em `leaderstats.Memories`.
7. Ativar 3 POIs com `ProximityPrompt` e confirmar incremento em `leaderstats.POIs`.
8. Confirmar que duplicatas nao aumentam os contadores.
9. Confirmar que o portao da Sala Final abre apos 12 memorias e 3 POIs.
10. Jogar por 2 minutos sem erros vermelhos no Output.
11. Confirmar que o circuito completo cabe em 5 a 10 minutos.
