class_name MapGenConfig extends Resource

## Size of the map in cells, including the outer water ring.
@export var size: Vector2i = Vector2i(45, 45)
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
## The base lies at least this many cells from every map edge.
@export var base_margin: int = 10
## Spawners lie within this many cells of the land edge.
@export var spawner_edge_band: int = 4
## Cells around the base and each spawner that stay plain grass.
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
