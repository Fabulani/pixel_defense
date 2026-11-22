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
## Templates drawn for normal waves (includes [member normal_template]; not the boss template).
@export var templates: Array[WaveTemplate] = []
## Template of spawners in a wave without a special draw.
@export var normal_template: WaveTemplate
## Template of the boss slot.
@export var boss_template: WaveTemplate
## Every [member boss_interval]-th wave (and the last one) has a boss slot.
@export var boss_interval: int = 10


## Budget of the wave at [param index].
func budget(index: int) -> float:
	return (base_budget + budget_per_wave * index) * pow(budget_growth, index)


## Creates the rng of one wave: seeded from [param wave_seed] and the wave [param index] only.
static func make_rng(wave_seed: int, index: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([wave_seed, index])
	return rng


## Whether the wave at [param index] has a boss slot.
func is_boss_wave(index: int) -> bool:
	return (boss_interval > 0 and index % boss_interval == boss_interval - 1) or index == max_waves - 1


## Builds the plan of the wave at [param index] for [param open_spawners] spawners, drawing only
## from [param rng]. [param last_templates][k] is the template open spawner k used in its previous
## wave (missing or null = none); a special template is not drawn twice in a row for a spawner.
## [param difficulty] multiplies the wave budget (1.0 = normal).
## Draw order: boss slot, template per spawner, then each spawner's enemies.
func generate(index: int, rng: RandomNumberGenerator, open_spawners: int, last_templates: Array[WaveTemplate] = [], difficulty: float = 1.0) -> WavePlan:
	var plan := WavePlan.new()
	plan.index = index
	var count: int = maxi(1, open_spawners)

	var boss_slot: int = -1
	if boss_template != null and is_boss_wave(index):
		boss_slot = rng.randi_range(0, count - 1)

	for k: int in range(count):
		var sp := SpawnerPlan.new()
		if k == boss_slot:
			sp.template = boss_template
		elif boss_slot >= 0:
			sp.template = normal_template
		else:
			var last: WaveTemplate = last_templates[k] if k < last_templates.size() else null
			sp.template = _draw_template(index, rng, last)
		plan.spawners.append(sp)

	var share: float = budget(index) * difficulty / count
	for sp: SpawnerPlan in plan.spawners:
		var multiplier: float = sp.template.budget_multiplier if sp.template != null else 1.0
		sp.budget = share * multiplier
		_fill(index, rng, sp)
		plan.budget += sp.budget
		plan.spent += sp.spent
	return plan


## Draws a template by weight among those open at [param index]; [param last] is excluded if special.
func _draw_template(index: int, rng: RandomNumberGenerator, last: WaveTemplate) -> WaveTemplate:
	var eligible: Array[WaveTemplate] = []
	var total: float = 0.0
	for template: WaveTemplate in templates:
		if template == null or template.weight <= 0.0 or template.first_wave > index:
			continue
		if template.is_special and template == last:
			continue
		eligible.append(template)
		total += template.weight
	if eligible.is_empty():
		return normal_template
	var roll: float = rng.randf() * total
	for template: WaveTemplate in eligible:
		roll -= template.weight
		if roll < 0.0:
			return template
	return eligible[eligible.size() - 1]


## Spends [member SpawnerPlan.budget] of [param sp] on enemies, weighted by its template.
func _fill(index: int, rng: RandomNumberGenerator, sp: SpawnerPlan) -> void:
	var total_weight: float = 0.0
	for entry: WaveEnemy in enemies:
		if entry != null and entry.scene != null and entry.cost > 0:
			total_weight += maxf(entry.weight, 0.0)
	if total_weight <= 0.0:
		push_error("WaveConfig: no enemies with weight > 0; empty wave.")
		return

	var remaining: float = sp.budget
	var spent_by_entry: Array[int] = []
	spent_by_entry.resize(enemies.size())
	spent_by_entry.fill(0)

	while true:
		var eligible: Array[int] = []
		var weights: Array[float] = []
		var eligible_weight: float = 0.0
		for i: int in range(enemies.size()):
			var entry: WaveEnemy = enemies[i]
			if entry == null or entry.scene == null or entry.cost <= 0 or entry.weight <= 0.0:
				continue
			if entry.first_wave > index or entry.cost > remaining:
				continue
			if entry.max_share < 1.0 and spent_by_entry[i] + entry.cost > entry.max_share * sp.budget:
				continue
			var multiplier: float = sp.template.get_multiplier(entry.scene) if sp.template != null else 1.0
			var weight: float = entry.weight * multiplier
			if weight <= 0.0:
				continue
			eligible.append(i)
			weights.append(weight)
			eligible_weight += weight
		if eligible.is_empty():
			if sp.enemies.is_empty():
				push_warning("WaveConfig: no enemy eligible for wave %d (budget %.1f); empty spawner." % [index, sp.budget])
			break

		var roll: float = rng.randf() * eligible_weight
		var picked: int = eligible[eligible.size() - 1]
		for j: int in range(eligible.size()):
			roll -= weights[j]
			if roll < 0.0:
				picked = eligible[j]
				break

		var chosen: WaveEnemy = enemies[picked]
		sp.enemies.append(chosen.scene)
		remaining -= chosen.cost
		spent_by_entry[picked] += chosen.cost
		sp.spent += chosen.cost
