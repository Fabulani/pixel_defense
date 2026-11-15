class_name TowerStats extends Resource

@export var cost: int = 3  ## Cost to build
@export var damage: float = 1.0  ## Damage per shot
@export var shots_per_second: float = 2.0  ## Shots per second
@export var detection_range: float = 100.0  ## Detection range
@export var penetration: int = 1  ## Maximum number of projectile hits
@export var knockback: float = 20.0  ## Initial knockback speed (px/s) applied to an enemy on hit; decays quickly
@export var recoil: float = 2.0  ## Cannon recoil distance in px
const MAX_LEVEL: int = 5  ## Level reached by picking a major upgrade

@export var upgrade_bonus_per_level: float = 0.1  ## Additive bonus to damage, fire rate and range per level
@export var major_cost: int = 50  ## Cost of the major upgrade (level 4 -> 5)


## Cost of the upgrade that takes a tower to [param next_level].
## Levels 1..MAX_LEVEL-1 cost `cost * next_level`; MAX_LEVEL costs `major_cost`. Anything else returns 0.
func upgrade_cost(next_level: int) -> int:
	if next_level >= 1 and next_level < MAX_LEVEL:
		return cost * next_level
	if next_level == MAX_LEVEL:
		return major_cost
	return 0
