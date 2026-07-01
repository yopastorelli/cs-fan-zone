# AI_VISUAL_QA

## REQUIRED_SCREENSHOTS
- lobby spawn
- lobby reveal
- preview base
- Planicie
- Deserto
- Taiga
- Selva
- Neve
- Cogumelos
- Ilha do Meio
- Centro
- HUD `Lobby`
- HUD `Active`

## COMPARE_REQUIRED
- `Low` vs `Standard`
- `Lobby` before/after
- `Neve` before/after
- `Centro` before/after
- `ShadowMap` vs `Future` only if `Standard` is under review

## PASS_CRITERIA
- o lobby nao parece vazio nem poluido por labels
- o centro e legivel no primeiro frame
- as Ilhas do Meio nao somem no horizonte
- cada bioma e reconhecivel sem ler placa
- o mapa parece mais proximo de Minecraft por massa, strata e material
- o totem continua sendo o elemento mais importante da base
- bloom nao apaga forma ou material
- HUD continua legivel em viewport mobile

## FAIL_CONDITIONS
- glow maior que a leitura do terreno
- billboard ou signage mais forte que landmark e rota
- preview de base rouba a cena do reveal
- ilha importante some contra o ceu
- brilho premium existe em todo lugar e nao so em recompensa
- `Low` perde clareza ou jogabilidade
