# No feedback when pressing an unaffordable upgrade (TowerMenu)

- **Type:** bug / UX
- **Priority:** medium
- **Area:** UI, building
- **Status:** seen on mobile in playtests (not rechecked on the latest build)

## Description
When the player can't afford an upgrade, `TowerMenu` dims the button *and* sets `button.disabled = true` (`ui/tower_menu/tower_menu.gd` `_add_button` / `_on_currency_manager_currency_changed`). A disabled `Button` never emits `pressed`, so the press does nothing at all, on every platform. The dimming is the only cue, and it's easy to miss on a phone.

The `BuildingManager.upgrade_denied` → `HighlightTile.flash_denied()` path exists, but the menu practically never reaches it. When it does fire (for example when coins change between the refresh and the press), it flashes the cell under the pointer, which is under the menu, not the tower. On touch `HighlightTile` is hidden, and it only shows for the flash.

## Ideas
- Keep unaffordable buttons enabled but dimmed, and let the press go through to `BuildingManager`, so `upgrade_denied` fires.
- Give the feedback on the tower (a red `flash_color` via `TurretComponent.flash()`), on the button (shake or red flash), and/or by blinking the HUD coin counter.
- Keep the 300 ms press guard and the no-leak-to-map behaviour (a disabled button still eats the touch today; check that an enabled one does too).

## Done when
Pressing an unaffordable upgrade gives clear feedback on desktop and on a phone.
