class_name WaveConfig extends Resource
## Describes how big the waves are and which enemies they are made of.

## Number of waves before the game is won.
@export var max_waves: int = 20
## Budget of wave 0.
@export var base_budget: float = 4.0
## Budget added per wave index (before growth).
@export var budget_per_wave: float = 2.0
## Per wave multiplier applied as pow(budget_growth, index).
@export var budget_growth: float = 1.08
## Enemy types the budget is spent on.
@export var enemies: Array[WaveEnemy] = []


## Budget of the wave at [param index].
func budget(index: int) -> float:
	return (base_budget + budget_per_wave * index) * pow(budget_growth, index)


## Creates the rng of one wave: seeded from [param wave_seed] and the wave [param index] only.
static func make_rng(wave_seed: int, index: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([wave_seed, index])
	return rng


## Builds the plan of the wave at [param index], drawing only from [param rng].
func generate(index: int, rng: RandomNumberGenerator) -> WavePlan:
	var plan := WavePlan.new()
	plan.index = index
	plan.budget = budget(index)

	var total_weight: float = 0.0
	for entry: WaveEnemy in enemies:
		if entry != null and entry.scene != null and entry.cost > 0:
			total_weight += maxf(entry.weight, 0.0)
	if total_weight <= 0.0:
		push_error("WaveConfig: no enemies with weight > 0; empty wave.")
		return plan

	var remaining: float = plan.budget
	var spent_by_entry: Array[int] = []
	spent_by_entry.resize(enemies.size())
	spent_by_entry.fill(0)

	while true:
		var eligible: Array[int] = []
		var eligible_weight: float = 0.0
		for i: int in range(enemies.size()):
			var entry: WaveEnemy = enemies[i]
			if entry == null or entry.scene == null or entry.cost <= 0 or entry.weight <= 0.0:
				continue
			if entry.first_wave > index or entry.cost > remaining:
				continue
			if entry.max_share < 1.0 and spent_by_entry[i] + entry.cost > entry.max_share * plan.budget:
				continue
			eligible.append(i)
			eligible_weight += entry.weight
		if eligible.is_empty():
			if plan.enemies.is_empty():
				push_warning("WaveConfig: no enemy eligible for wave %d (budget %.1f); empty wave." % [index, plan.budget])
			break

		var roll: float = rng.randf() * eligible_weight
		var picked: int = eligible[eligible.size() - 1]
		for i: int in eligible:
			roll -= enemies[i].weight
			if roll < 0.0:
				picked = i
				break

		var chosen: WaveEnemy = enemies[picked]
		plan.enemies.append(chosen.scene)
		remaining -= chosen.cost
		spent_by_entry[picked] += chosen.cost
		plan.spent += chosen.cost

	return plan
