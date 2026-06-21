# AI_UI_UX_SPEC

TARGET: competitive Roblox arena UI comparable to strong public alpha experiences
LANGUAGE: Portuguese
INPUT: desktop and mobile

## UI_STATES
- Lobby: compact objective card, queue count, current state, no resource or standings clutter.
- Starting: central countdown, clear automatic team allocation message.
- Active: timer top center, own team/core left, resources bottom center, standings right.
- Spectating: eliminated banner, standings visible, no shop/resource interaction prompt.
- Ended: victory/draw banner, return-to-lobby text.

## LAYOUT_RULES
- use AnchorPoint for top, side and bottom anchored panels
- use UIScale for screen-size adaptation
- use UIPadding, UIListLayout and UIGridLayout for repeated elements
- avoid fixed offsets as the only responsive strategy
- no text clipping on small viewport
- no full-screen onboarding card during active gameplay
- world-space labels must not dominate the lobby frame
- shop, upgrade and generator naming should be local/contextual, not giant global billboards
- HUD must remain visually stronger than distant world labels in the first 10 seconds

## SHOP_MODAL
- categories: Blocos, Combate, Ferramentas, Suporte, Upgrades
- each item must show display name, resource, cost and availability
- affordable item: strong accent button
- unaffordable item: muted button with clear missing-resource state
- max upgrade: disabled state
- close button must be visible on desktop and mobile

## FEEDBACK
- purchase success: green pulse and short message
- purchase denied: red pulse and short message
- upgrade applied: green message
- resource collected: subtle resource chip pulse
- core hit: warning message
- core destroyed: large danger announcement
- victory/draw: centered result banner

## ACCEPTANCE
- player understands lobby objective in 10 seconds
- player knows own core state during active match
- player knows resources and purchase availability
- UI does not obscure combat center on desktop or mobile
- top HUD remains readable even when the arena is bright
