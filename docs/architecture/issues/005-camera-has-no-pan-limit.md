# The camera can pan off the map forever

- **Type:** bug
- **Priority:** medium
- **Area:** controls
- **Status:** seen in playtests

## Description
`PanningCamera.fit_rect()` limits zoom out (`min_zoom`), but `smooth_damp.position_goal` is never clamped. Touch drag, mouse pan and WASD/stick can all move the camera far away from the island.

## Files
- `core/controls/panning_camera.gd`, `core/controls/smooth_damp/smooth_damp.gd`

## Fix idea
Store the map rect in `fit_rect()`. After every goal change (pan handlers, directional input, and the zoom-anchor offset), clamp `position_goal` so the view centre (or the view rect, depending on zoom) stays inside the map rect plus a margin. Clamp the goal, not the output, so the spring stays smooth.

## Done when
You can't pan the map fully out of view at any zoom, and zoom-to-cursor still feels right near the edges.
