class_name EnemySpawner extends Node2D

signal spawning_complete
signal enemy_count_changed(count: int)

@export var current_spawn_list: Array[PackedScene] = []
@export var default_spawn_delay : float = 1.0

@onready var spawn_timer: Timer = $EnemySpawnTimer

var spawn_delay : float = 0.0
var spawn_list_index : int = 0
var alive_enemy_count : int = 0

var target_pos : Vector2

func _ready() -> void:
	spawn_delay = default_spawn_delay
	spawn_timer.wait_time = spawn_delay
	
func start_spawning(spawn_list: Array) -> void:
	current_spawn_list.assign(spawn_list)
	spawn_list_index = 0
	spawn_timer.start()

func spawn_next() -> void:
	if spawn_list_index >= current_spawn_list.size():
		spawn_timer.stop()
		spawning_complete.emit()
		# Next time, spawn faster. For fun.
		speedup_spawning()
		return

	var enemy = current_spawn_list[spawn_list_index].instantiate()
	enemy.target_pos = target_pos
	enemy.died.connect(_on_enemy_died)
	enemy.tree_exiting.connect(_on_enemy_removed)
	add_child(enemy)
	enemy.add_to_group("enemy_group")
	alive_enemy_count += 1
	enemy_count_changed.emit(alive_enemy_count)

func speedup_spawning() -> void:
	spawn_delay = max(0.01, spawn_delay - 0.1)
	spawn_timer.wait_time = spawn_delay

func _on_enemy_died(enemy: EnemyEntity) -> void:
	CurrencyManager.earn(enemy.stats.coins)

func _on_enemy_removed() -> void:
	alive_enemy_count -= 1
	enemy_count_changed.emit(alive_enemy_count)

func _on_enemy_spawn_timer_timeout() -> void:
	spawn_next()
	spawn_list_index += 1
