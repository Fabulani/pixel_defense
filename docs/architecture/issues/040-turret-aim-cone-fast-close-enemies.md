# Slow cannons (big_boy) may never shoot fast enemies up close

- **Type:** design / playtest
- **Priority:** low
- **Area:** towers

A turret fires only when a target's lead point is within `aim_tolerance` of the cannon. A fast enemy close to a slow-turning cannon (big_boy, turn ×0.35) can stay outside the cone and never be shot. Check in playtest. If it is a problem: widen the tolerance with distance, or prefer the target that needs the least turn (belongs to targeting priorities, issue #10).

Related, not planned: enemy turning still looks abrupt at path corners. Lowering `EnemyStats.turn_speed` makes enemies slide sideways, because movement follows the path at once; smoothing the movement itself (rounded corners) would be needed.
