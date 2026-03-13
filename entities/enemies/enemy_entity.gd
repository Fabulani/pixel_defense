class_name EnemyEntity extends CharacterBody2D

signal died(enemy: EnemyEntity)

@export var stats: EnemyStats
#@export var drops: EnemyDrops
@export var pathfinding: Pathfinding
#@export var health: Health

var health: int


func _ready() -> void:
	health = stats.max_health
	add_to_group("enemies")

func _process(_delta: float) -> void:
	pathfinding.move()

func hit(damage: int) -> void:
	health -= damage
	if health <= 0:
		die()
		
func die() -> void:
	died.emit(self)
	queue_free()
