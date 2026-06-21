# CS Fan Zone

MVP Roblox de exploracao para fas da comunidade CS, com foco em coletaveis, pontos de interesse, easter eggs e aprendizado de Luau.

## Rodar localmente

Use o WSL para evitar problemas do Git no caminho `\\wsl$`:

```bash
cd /home/danie/projetos/cs-fan-zone
rokit install
~/.rokit/bin/rojo build -o build.rbxlx
~/.rokit/bin/rojo serve
```

Depois, abra o Roblox Studio no Windows e conecte o plugin do Rojo em `localhost:34872`.

## Regras de conteudo

- Sem IP de terceiros sem licenca explicita.
- Sem nomes reais, logos, vozes, imagens, slogans exatos ou avatares reconheciveis.
- Sem links off-platform nem coleta de dados pessoais.
- Toda midia externa precisa de registro em `docs/asset-register.md`.
- Creditos obrigatorios ficam em `docs/ATTRIBUTIONS.md`.

## Estrutura

- `src/Shared`: configuracao, modulos puros e contratos compartilhados.
- `src/Server`: bootstrap do mundo e regras autoritativas de gameplay.
- `src/Client`: HUD e feedback visual local.
- `docs`: setup, playtests, compliance e licencas.
- `assets`: fontes locais e comprovantes de licenca.
