# NextWaveButton: a double press leaks to the map; the button blocks map cells

- **Type:** bug
- **Priority:** low
- **Area:** UI, controls

- `%NextWaveButton` hides on the first press, so a fast double press puts the second press on the map (deselect, or a build ghost at the bottom-centre cell). A press released just as the countdown ends does the same.
- While visible, the button (180×72, bottom centre) eats presses on the map cells under it.

Fix ideas: keep the button visible but disabled for about 300 ms after a press (like `TowerMenu`'s guard), and/or block map input for a short time after any GUI press.
