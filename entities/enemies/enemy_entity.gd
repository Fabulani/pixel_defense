class_name EnemyEntity extends CharacterBody2D

signal died(enemy: EnemyEntity)

@export var stats: EnemyStats
@export var drops: EnemyDrops
@export var pathfinding: Pathfinding
@export var health: Health

func _ready() -> void:
	health.hp = stats.max_health
	health.depleted.connect(_on_health_depleted)
	add_to_group("enemies")

func _process(_delta: float) -> void:
	pathfinding.move()

func take_damage(amount: float) -> void:
	health.take_damage(amount)
		
func die() -> void:
	died.emit(self)
	queue_free()

func _on_health_depleted() -> void:
	die()
