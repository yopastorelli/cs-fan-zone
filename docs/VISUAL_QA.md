# AI_VISUAL_QA

## REQUIRED_SCREENSHOTS
- lobby initial spawn
- lobby arena overlook
- Planicie base
- Deserto base
- Taiga base
- Selva base
- Neve base
- Cogumelos base
- center island
- mid island
- item shop modal
- countdown
- active HUD
- core destroyed
- victory or draw banner

## PASS_CRITERIA
- first screenshot does not look empty
- each biome is distinguishable by silhouette and palette
- core, shops and generators are visible within 5 seconds after spawning at base
- center is visually stronger than side islands
- no debug-looking flat platforms dominate the scene
- no UI text is clipped
- no important world object is hidden behind UI
- no red errors in Studio Output for 5 minutes

## FAIL_CONDITIONS
- any base relies on text label as primary identity
- lobby spawn faces empty space
- platforms look like unstyled rectangles
- UI overlaps active combat controls or hides resources
- visual props block routes, spawn, shops, generators or core
- particle or light spam causes visible performance drop
