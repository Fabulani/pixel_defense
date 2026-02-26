class_name EnemySpawner extends Node2D

signal spawning_complete

@export var current_spawn_list: Array[PackedScene] = []
@export var default_spawn_delay : float = 1.0

@onready var spawn_timer: Timer = $EnemySpawnTimer

var current_spawn_delay : float = 0.0
var spawn_list_index : int = 0

var pathfinding : PathfindingManager
var target_pos : Vector2
var currency : CurrencyManager

func _ready() -> void:
	current_spawn_delay = default_spawn_delay
	spawn_timer.wait_time = current_spawn_delay
	
func start_spawning(spawn_list: Array) -> void:
	current_spawn_list.assign(spawn_list)
	spawn_list_index = 0
	spawn_timer.start()

func spawn_next() -> void:
	if spawn_list_index >= current_spawn_list.size():
		spawn_timer.stop()
		spawning_complete.emit()
		return

	var enemy = current_spawn_list[spawn_list_index].instantiate()
	enemy.pathfinding = pathfinding
	enemy.target_pos = target_pos
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)
	enemy.add_to_group("enemy_group")


func _on_enemy_died(enemy: EnemyEntity) -> void:
	currency.earn(enemy.stats.coins)

func _on_enemy_spawn_timer_timeout() -> void:
	spawn_next()
	spawn_list_index += 1
