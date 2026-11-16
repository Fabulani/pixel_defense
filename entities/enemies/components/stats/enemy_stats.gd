class_name EnemyStats extends Resource

@export var speed: float
@export var max_health: int
@export var knockback_scale: float = 1.0  ## Multiplies knockback received
@export var vfx_color: Color = Color(0.8, 0.8, 0.8)  ## Particle colour for hits and deaths
@export var armor: float = 0.0  ## Flat damage removed from every hit
@export var min_damage_share: float = 0.25  ## With armor, a hit still does at least this share of its damage
@export var death_spawn_scene: PackedScene  ## Enemy spawned where this one dies (see EnemySpawner)
@export var death_spawn_count: int = 0  ## How many death_spawn_scene enemies to spawn
