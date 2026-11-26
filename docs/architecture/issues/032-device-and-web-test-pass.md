# Device and Web test pass (phone, mobile Web, touchscreen laptop)

- **Type:** test
- **Priority:** high
- **Area:** all

Many systems are verified only by headless runs with injected events, or by the author on PC. One pass on real devices should cover:
- the touch/mouse separation (issue #18): if a platform sends synthesized mouse events with a real device id, one tap would arrive as both `tapped` and `clicked`;
- TowerMenu placement and size at different zooms and near screen edges, the hue-swap colours, the level label, and the 0.8 cannon scale;
- the countdown button and the wave banner;
- the game-feel effects on Web (GPU particles and trails on the Compatibility renderer, stutter on first emission) and the Android frame rate in late waves;
- the enemy state effects (smoke, pluses, dash trail, deflect): look and cost;
- the debug menu on touch.

Turn each finding into its own issue.
