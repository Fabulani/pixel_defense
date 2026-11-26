# Fast wheel scrolling loses zoom steps

- **Type:** bug
- **Priority:** low
- **Area:** controls

## Description
Zoom is read with `Input.is_action_just_pressed()` once per frame, so several wheel ticks within one frame give only one zoom step. It's an `if`/`elif`, so zoom-in also wins when both directions happen in the same frame.

## Fix
Handle wheel events one by one in `_unhandled_input`; see 004, which fixes this too. Optionally scale the step by `InputEventMouseButton.factor` for smooth-scrolling touchpads.

## Done when
N wheel ticks give N zoom steps.
