# CS Fan Zone setup

Execute tudo a partir do WSL para evitar o problema de `dubious ownership` do Git no caminho `\\wsl$`.

## Bootstrap local

```bash
cd /home/danie/projetos/cs-fan-zone
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
source ~/.bashrc
rokit install
~/.rokit/bin/rojo plugin install
~/.rokit/bin/rojo build -o build.rbxlx
~/.rokit/bin/rojo serve
```

Se `rojo` ainda nao estiver no `PATH`, use `~/.rokit/bin/rojo` explicitamente como acima.

## Roblox Studio

1. Abra o Roblox Studio.
2. Confirme que o plugin do Rojo foi instalado.
3. Abra a experiencia de destino ou crie uma nova.
4. No plugin do Rojo, conecte ao servidor local `localhost:34872`.
5. Rode `File -> Publish to Roblox`.
6. Ajuste privacidade e permissoes no dashboard da experiencia.

## Fluxo Git/GitHub

```bash
cd /home/danie/projetos/cs-fan-zone
git status
git add .
git commit -m "Bootstrap CS Fan Zone"
git push -u origin feat/bootstrap-world
gh pr create --fill --base main
```
