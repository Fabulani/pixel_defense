# Refactor the controls into explicit classifier / consumer / output layers

- **Type:** refactor
- **Priority:** low (scoped revisit later)
- **Area:** controls

## Description
The controls already follow three layers in spirit (see `docs/architecture/07-controls.md`, diagram 1), but the data flow is tangled:

- Classifiers are children of `PanningCamera`, even though `InputController` uses them too. `Main` reaches into `camera.touch_controls`.
- `PanningCamera` pushes action names into `KBMControls` and calls its `setup()`.
- `PanningCamera` polls `Input.get_vector` for keyboard and stick panning itself, so that classification lives in the consumer.
- `KBMControls` polls zoom actions in `_process`, which skips GUI consumption (004).
- The two classifiers emit different signal vocabularies for the same intents (`pan_changed` vs `mouse_panned`, `tapped` vs `clicked`, `pinch_changed` vs `zoomed`).

## Proposal (to be scoped)
1. **Classifiers** (`TouchControls`, `KBMControls`, plus a small `PadControls`/keyboard classifier) emit one shared intent vocabulary: `point_selected(screen_pos)`, `pan_requested(screen_delta)`, `zoom_requested(factor, anchor)` (or a pinch variant that carries its start zoom).
2. One **input router** node (or `Main`) connects every classifier to the **consumers**: `CameraRig`/`PanningCamera` for pan and zoom, `InputController` for point selection. The consumers stop knowing which device sent the intent.
3. **Output** stays as it is: goals → `SmoothDamp` → `position`/`zoom`; `CameraShake` → `offset`. Add the pan clamp (005) here.

Classifiers become siblings rather than camera children, and action names live in the classifiers themselves.

## Risks
The touch/mouse separation (issue #18) was verified only with injected events. Any refactor needs the same headless injection checks, plus a device test.

## Done when
There is one intent vocabulary, no consumer reads `Input` directly, and the diagram has one arrow per intent.
