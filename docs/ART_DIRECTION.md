# AI_ART_DIRECTION

PROJECT: CS Fan Zone Arena
TARGET: visual upgrade for ages `10-14`
BASELINE: `mobile fraco`
STYLE: `quase Minecraft`, mas original; voxel-heavy, blocky, modular, sem copiar textura, sprite ou iconografia oficial

## VISUAL_PILLARS
- `SilhouetteFirst`: cada bioma precisa ser reconhecivel pela massa antes do texto
- `DepthBeforeGlow`: profundidade vem de strata, borda, sombra e material antes de neon
- `HeroReadability`: totem, Ilha do Meio e Centro precisam dominar a leitura
- `LobbyReveal`: o primeiro frame vende a arena, nao a sinalizacao
- `LowTierSafe`: o tier `Low` e a versao canonica de desempenho

## MATERIAL_LANGUAGE
- terreno: `Grass`, `Ground`, `Rock`, `Sand`, `Sandstone`, `Snow`, `Mud`, `Slate`
- construcao: `WoodPlanks`, `Wood`, `Rock`
- premium: `SmoothPlastic` so para contraste controlado
- recompensa: `Neon` so para esmeralda/totem e nunca como base do look

## BIOME_RULES
- `Planicie`: terra e grama em degraus, flores voxel, cercas, abrigo simples
- `Deserto`: dunas em blocos, arenito em terraços, ruina seca, cactos cubicos
- `Taiga`: pedra fria, pinheiros em camadas, madeira escura, pilha de pedra
- `Selva`: troncos altos, canopia densa, passarela de madeira, massa vegetal pesada
- `Neve`: gelo e neve em placas, picos frios, contraste mais limpo
- `Cogumelos`: mycelium, cogumelos blocados, recorte mais excentrico

## QUALITY_TIER_RULES
- `Low`: `ShadowMap`, sem `SunRays`, sem glow decorativo, luz/partícula só para leitura
- `Standard`: `Future`, brilho moderado, shrine/centro mais ricos, mas mesma linguagem
- nenhum asset visual pode existir sem categoria: `GameplayCritical`, `ReadabilitySupport`, `PureDecor`

## PROHIBITED
- copiar textura oficial de Minecraft
- copiar sprite oficial de esmeralda
- glow em superfícies grandes como linguagem principal
- signage gigante dominando lobby ou centro
- biomas diferenciados só por texto
