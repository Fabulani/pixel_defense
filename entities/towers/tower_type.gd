class_name TowerType extends Resource

@export var id: StringName  ## Unique key of the kind
@export var display_name: String  ## Name shown to the player
@export var scene: PackedScene  ## Tower scene; its root must be a [Tower]
@export var stats: TowerStats  ## Base stats; the source of cost and range
@export var base_texture: Texture2D  ## Base sprite, used for the build button icon and the build ghost
@export var turret_texture: Texture2D  ## Cannon sprite, drawn over the base in the icon and the ghost
@export var turret_scale: float = 1.0  ## Scale of the cannon sprite in the icon and the ghost
