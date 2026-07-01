# AI_PERFORMANCE_BUDGET

BASELINE: mobile fraco
DEFAULT_TIER: `Low`
OPTIONAL_TIER: `Standard`

## LOW_TIER_BUDGET
- `Technology`: `ShadowMap`
- `ScreenGui`: `1`
- `PointLight` permanentes: max `20`
- `ParticleEmitter` permanentes: max `12`
- `BillboardGui` sempre visíveis: max `12`
- `SurfaceGui` duplos: max `28`
- `SunRays`: desligado
- `Bloom`: apenas suporte leve de profundidade, nunca highlight principal
- `IslandGlow`: desligado
- `PureDecor` com luz/partícula: desligado por default

## STANDARD_TIER_BUDGET
- `Technology`: `Future`
- `PointLight` permanentes: max `34`
- `ParticleEmitter` permanentes: max `20`
- `BillboardGui` sempre visíveis: max `18`
- `SurfaceGui` duplos: max `36`
- `SunRays`: permitido
- `IslandGlow`: permitido
- `PureDecor` com luz/partícula: permitido de forma seletiva

## PRIORITY_RULES
- `GameplayCritical`: totem, esmeralda premium, leitura de gerador, feedback de objetivo
- `ReadabilitySupport`: beacon de rota, shrine premium, reforco de navegacao
- `PureDecor`: backdrop glow, luz cenica, partícula ambiente, enfeite sem impacto de leitura
- em `Low`, `PureDecor` e o primeiro alvo de corte
- em qualquer tier, decoracao nunca pode bloquear spawn, loja, upgrade, rota, totem ou gerador

## MATERIAL_RULES
- preferir `Rock`, `Ground`, `Grass`, `Sand`, `Snow`, `Mud`, `WoodPlanks`, `Slate`
- limitar `SmoothPlastic` a placas, trim, totens e elementos de contraste
- limitar `Neon` a esmeralda premium, destaque de totem e pontos de recompensa
- evitar superficies grandes com transparencia

## VALIDATION
- `~/.rokit/bin/rojo build -o build.rbxlx`
- `~/.rokit/bin/rojo serve`
- alternar `Config.Visual.VisualQualityDefault` entre `Low` e `Standard` para comparativo controlado
- Studio Play desktop por `5 min` sem erros vermelhos
- viewport mobile sem clipping e sem perder leitura das rotas
- screenshots comparativos `Low` vs `Standard` para: lobby, Neve, Centro
- `SmokeTests.server.lua` valida contagem de `PointLight`, `ParticleEmitter`, `BillboardGui`, `SurfaceGui`, bases, triggers do meio e geradores centrais
