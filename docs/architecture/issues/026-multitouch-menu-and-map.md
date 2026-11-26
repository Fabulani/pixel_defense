# Multi-touch across TowerMenu and the map is not coordinated

- **Type:** bug
- **Priority:** low
- **Area:** controls, UI

- A finger held on a menu button does not block a second finger's map tap.
- A pinch that starts with one finger on a button can't zoom: the GUI eats that finger's press, so `TouchControls` never sees it.

Decide the intended behaviour (probably: a finger on the GUI blocks map taps; a pinch can start anywhere) and add it to the classifier (see also 009).
