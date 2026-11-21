class_name MapGenConfig extends Resource

## Size of the map in cells, including the outer water ring.
@export var size: Vector2i = Vector2i(50, 50)
## Minimum number of spawners.
@export var spawner_count_min: int = 2
## Maximum number of spawners.
@export var spawner_count_max: int = 2
## `first_wave` of the i-th spawner; spawners beyond the list reuse the last entry.
@export var spawner_first_waves: Array[int] = [0, 2, 5]
## Minimum Euclidean distance (cells) between a spawner and the base.
@export var min_spawner_base_distance: int = 22
## Minimum Euclidean distance (cells) between two spawners.
@export var min_spawner_separation: int = 15
## The base lies at least this many cells from the coast (distance in steps from the nearest water cell).
@export var base_margin: int = 10
## Spawners lie between 2 and 1 + this many cells from the coast.
@export var spawner_edge_band: int = 4
## Cells around the base and each spawner that stay plain grass. Values below 2 are treated as 2 (the 8 neighbours of a marker always stay grass).
@export var keep_out_radius: int = 3
## Target share of interior cells that are lake water.
@export var lake_coverage: float = 0.06
## Frequency of the noise field that shapes lakes.
@export var lake_noise_frequency: float = 0.08
## Share of interior cells that hold a tree.
@export var tree_coverage: float = 0.08
## Share of the trees placed from noise clusters; the rest are scattered singly.
@export var tree_cluster_share: float = 0.6
## Share of all cells that get a decoration tile.
@export var decoration_density: float = 0.01
## Generation attempts before falling back to an empty map.
@export var max_attempts: int = 20

@export_group("Shape")
## Radius of the main island as a share of the map size (per axis, before the random stretch). 0.42 gives about 21 cells on 50x50.
@export var land_radius: float = 0.42
## Frequency of the noise field that makes the coast irregular.
@export var coast_noise_frequency: float = 0.07
## How strongly the coast noise moves the coastline (in units of the island radius).
@export var coast_noise_amplitude: float = 0.35
## Minimum share of interior cells that must be land; below it the attempt is dropped.
@export var min_land_share: float = 0.45

@export_group("Road")
## Weight of the noise that makes the road bend: a cell costs 1 + this * noise (0..1).
@export var road_wiggle: float = 2.0
## Road cells between two lamp posts.
@export var lamp_spacing: int = 6

@export_group("Farms")
## Multiplier of the number of farmland patches near the base.
@export var farmland_multiplier: float = 1.2
