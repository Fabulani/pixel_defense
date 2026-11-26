# `MobileDisplayHandler` has no visible effect

- **Type:** bug / dead code
- **Priority:** low
- **Area:** UI, mobile

## Description
`ui/mobile/mobile_display_handler.gd` sets safe-area margins on a `MarginContainer` that has no children and sits directly under the `Node2D` `Main`, so the margins move nothing. It only checks `OS.get_name()` for Android/iOS, so mobile Web is ignored.

## Fix
Either apply the safe area to the HUD, `TowerMenu` and the end screen (for example by wrapping each `CanvasLayer`'s root `Control` in it), or remove the node. Check on a notched phone.
