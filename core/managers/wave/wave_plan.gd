class_name WavePlan extends RefCounted
## The generated content of one wave.

## Wave index (0-based).
var index: int = 0
## Sum of the spawner budgets.
var budget: float = 0.0
## Sum of the threat points spent by the spawners.
var spent: int = 0
## One plan per open spawner, in open-spawner order.
var spawners: Array[SpawnerPlan] = []


## Whether any spawner has a special template.
func is_special() -> bool:
	for plan: SpawnerPlan in spawners:
		if plan.template != null and plan.template.is_special:
			return true
	return false
