extends RefCounted
## Debug toggles and selections. Static, so they survive reload_current_scene() (F1 / restart).

static var god_mode: bool = false
static var budget_scale: float = 1.0
static var countdown_held: bool = false
static var fast_spawn: bool = false
static var freeze_enemies: bool = false
static var invulnerable_enemies: bool = false
static var hold_fire: bool = false
static var time_scale: float = 1.0
static var open_sections: Dictionary[String, bool] = {}
static var enemy_name: String = ""
static var enemy_count: int = 1
static var spawn_location: int = 0
static var wave_number: int = 1
