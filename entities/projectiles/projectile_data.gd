class_name ProjectileData extends RefCounted

var origin: Vector2
var angle: float
var damage: float
var penetration: int
var speed: float
var texture: Texture2D = null  ## Overrides the bullet sprite when set
var material: Material = null  ## Overrides the bullet sprite material when set

func _init(p_origin: Vector2, p_angle: float, p_damage: float, p_penetration: int, p_speed: float = 500) -> void:
	origin = p_origin
	angle = p_angle
	damage = p_damage
	penetration = p_penetration
	speed = p_speed
