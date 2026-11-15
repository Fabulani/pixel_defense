class_name ProjectileData extends RefCounted

var origin: Vector2
var angle: float
var damage: float
var penetration: int
var speed: float
var texture: Texture2D = null  ## Overrides the bullet sprite when set
var material: Material = null  ## Overrides the bullet sprite material when set
var knockback: float = 0.0  ## Knockback speed (px/s) applied to enemies hit
var trail_amount: int = 6  ## Particles in the bullet trail
var trail_lifetime: float = 0.15  ## Lifetime of the trail particles in seconds
var trail_particle_scale: float = 1.0  ## Size multiplier of the trail particles
var color: Color = Color(1.0, 0.9, 0.5)  ## Particle colour for this bullet

func _init(p_origin: Vector2, p_angle: float, p_damage: float, p_penetration: int, p_speed: float = 500) -> void:
	origin = p_origin
	angle = p_angle
	damage = p_damage
	penetration = p_penetration
	speed = p_speed
