class_name Enemy extends CharacterBody2D

signal died(enemy: Enemy)

@export var stats: EnemyStats
@export var drops: Drops
@export var pathfinding: Pathfinding
@export var health: Health


func _ready() -> void:
	health.hp = stats.max_health
	health.depleted.connect(_on_health_depleted)
	add_to_group("enemies")


func _physics_process(_delta: float) -> void:
	pathfinding.move()


## Apply damage to this enemy's health.
func take_damage(amount: float) -> void:
	health.take_damage(amount)


## Set the world position this enemy walks towards.
func set_target_position(pos: Vector2) -> void:
	pathfinding.target_position = pos


## Push the enemy with a knockback [param impulse] (px/s), scaled by its stats' knockback_scale.
func apply_knockback(_impulse: Vector2) -> void:
	pass


## Emit [signal died] and remove the enemy.
func die() -> void:
	died.emit(self)
	queue_free()


func _on_health_depleted() -> void:
	die()
