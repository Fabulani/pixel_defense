class_name ProjectileData extends RefCounted

var origin: Vector2
var angle: float
var damage: float
var penetration: int
var speed: float

func _init(p_origin: Vector2, p_angle: float, p_damage: float, p_penetration: int, p_speed: float = 500) -> void:
	origin = p_origin
	angle = p_angle
	damage = p_damage
	penetration = p_penetration
	speed = p_speed
