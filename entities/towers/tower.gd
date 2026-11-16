class_name Tower extends Node2D

## Relay for internal signal. Indicate that a projectile should be spawned.
signal shot(data: ProjectileData)
## Emitted after the level or major upgrade changed and stats/appearance were refreshed.
signal upgraded

@export var stats: TowerStats  ## Data container for the BASE tower stats (never mutated)
@export var _turret: TurretComponent  ## Component for detection, aiming, and firing
@export var major_upgrades: Array[MajorUpgrade]  ## Choices offered at the last upgrade
@export var placed_squash_time: float = 0.15  ## Seconds of the squash after building
@export var upgrade_flash_time: float = 0.15  ## Seconds of the white flash after an upgrade

var level: int = 0  ## Current level, 0..TowerStats.MAX_LEVEL
var major: MajorUpgrade = null  ## Set when the tower reaches MAX_LEVEL
var total_spent: int = 0  ## Coins spent on this tower; maintained by BuildingManager, do not change it here

var _effective_stats: TowerStats
var _bullet_material: ShaderMaterial = null
var _base_scale: Vector2 = Vector2.ONE
var _squash_tween: Tween = null

@onready var _base: Sprite2D = %Base
@onready var _level_label: Label = %LevelLabel

func _ready() -> void:
	_base_scale = _base.scale
	_turret.shot.connect(_on_shot)
	_apply_upgrades()
	add_to_group("towers")

## Return true when the tower reached the maximum level.
func is_max_level() -> bool:
	return level >= TowerStats.MAX_LEVEL

## Return true when the next upgrade must be a major upgrade.
func needs_major() -> bool:
	return level == TowerStats.MAX_LEVEL - 1

## Return the coin cost of the next upgrade, or 0 at max level.
func next_upgrade_cost() -> int:
	if is_max_level():
		return 0
	return stats.upgrade_cost(level + 1)

## Apply a general upgrade. Does not touch currency.
func upgrade() -> void:
	if level >= TowerStats.MAX_LEVEL - 1:
		push_warning("Tower.upgrade() is only valid below level %d" % (TowerStats.MAX_LEVEL - 1))
		return
	level += 1
	_apply_upgrades()
	_flash(upgrade_flash_time)
	upgraded.emit()

## Apply the final major upgrade. Does not touch currency.
func apply_major(new_major: MajorUpgrade) -> void:
	if not needs_major() or new_major == null:
		push_warning("Tower.apply_major() is only valid at level %d with a valid upgrade" % (TowerStats.MAX_LEVEL - 1))
		return
	major = new_major
	level = TowerStats.MAX_LEVEL
	_apply_upgrades()
	_flash(upgrade_flash_time)
	upgraded.emit()

## Play the build squash animation.
func play_placed() -> void:
	if _squash_tween != null:
		_squash_tween.kill()
	_base.scale = _base_scale * Vector2(1.3, 0.7)
	_squash_tween = create_tween()
	_squash_tween.tween_property(_base, "scale", _base_scale, placed_squash_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_turret.play_squash(placed_squash_time)

## Flash base and cannon white.
func _flash(duration: float) -> void:
	Flash.play(_base, duration)
	_turret.flash(duration)

## Return the effective detection range.
func get_range() -> float:
	return _effective_stats.detection_range

## Rebuild the effective stats and refresh turret, level label and appearance.
func _apply_upgrades() -> void:
	var level_mult: float = 1.0 + stats.upgrade_bonus_per_level * level
	var damage_mult: float = 1.0
	var rate_mult: float = 1.0
	var range_mult: float = 1.0
	var recoil_mult: float = 1.0
	if major != null:
		damage_mult = major.damage_multiplier
		rate_mult = major.fire_rate_multiplier
		range_mult = major.range_multiplier
		recoil_mult = major.recoil_multiplier
	_effective_stats = stats.duplicate()
	_effective_stats.damage = stats.damage * level_mult * damage_mult
	_effective_stats.shots_per_second = stats.shots_per_second * level_mult * rate_mult
	_effective_stats.detection_range = stats.detection_range * level_mult * range_mult
	_turret.configure(_effective_stats)
	_turret.set_recoil(stats.recoil * recoil_mult)

	# Show the level as a number; hidden at level 0 and at MAX_LEVEL (the major shows instead).
	_level_label.text = str(level)
	_level_label.visible = level > 0 and level < TowerStats.MAX_LEVEL

	if major != null:
		_base.material = MajorUpgrade.make_tint_material(major.base_tint)
		_turret.set_appearance(major.turret_texture, MajorUpgrade.make_tint_material(major.turret_tint), major.turret_scale)
		_bullet_material = MajorUpgrade.make_tint_material(major.bullet_tint)

## Create a ProjectileData object using the effective stats
func _package_projectile(origin: Vector2, angle: float) -> ProjectileData:
	var projectile_data := ProjectileData.new(
		origin,
		angle,
		_effective_stats.damage,
		_effective_stats.penetration
	)
	projectile_data.knockback = _effective_stats.knockback
	if major != null:
		projectile_data.texture = major.bullet_texture
		projectile_data.material = _bullet_material
		projectile_data.knockback *= major.knockback_multiplier
		projectile_data.trail_amount = major.trail_amount
		projectile_data.trail_lifetime = major.trail_lifetime
		projectile_data.trail_particle_scale = major.trail_particle_scale
		if major.bullet_tint.a > 0.0:
			projectile_data.color = major.bullet_tint
	return projectile_data

## Signal relay that packages projectile data
func _on_shot(origin: Vector2, angle: float) -> void:
	var projectile_data: ProjectileData = _package_projectile(origin, angle)
	shot.emit(projectile_data)
