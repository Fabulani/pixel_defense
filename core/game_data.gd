extends Node

var grid_cell_size: Vector2i = Vector2i.ONE

## Seed for the next generated maps; -1 means a new random seed each run. Valid seeds are >= 1.
## It stays set until changed, so every run (restart, F1) replays that map.
var requested_seed: int = -1

## Play the hand-made map instead of a generated one.
var legacy_map: bool = false

## Seed of the map currently loaded (0 only for the legacy map; generated maps use seeds >= 1). Written by Level.
var map_seed: int = 0


## Reads the user arguments once: `--seed=<int>` and `--legacy-map` (usage: `godot -- --seed=12345`).
func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			var value: String = arg.trim_prefix("--seed=")
			if value.is_valid_int() and value.to_int() >= 1:
				requested_seed = value.to_int()
			else:
				push_warning("GameData: ignoring invalid seed '%s' (expected an integer >= 1)." % value)
		elif arg == "--legacy-map":
			legacy_map = true
