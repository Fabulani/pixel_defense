# TowerMenu: a double press leaks to the map when the button row shrinks

- **Type:** bug
- **Priority:** low
- **Area:** UI

When the row shrinks after a press (choosing the last major turns three majors + sell into sell only), a fast second press lands where a button used to be, so it hits the map: it deselects the tower and may start a build ghost. The 300 ms guard only covers buttons that still exist.

Related: on touch, a short drag that starts on a menu button still presses it (the camera doesn't pan), and closing the menu by tapping a cell also runs that cell's normal action (denied flash or build ghost). Decide if these are intended.
